// StoreService.swift
// StoreKit 2 기반 인앱결제 서비스 — 프리미엄 구독 관리

import Foundation
import StoreKit
import os

/// 프리미엄 구독 상품 ID
enum StoreProduct {
    static let premiumMonthly = "com.teamentangle.focustimer.premium.monthly"
}

/// StoreKit 2 기반 인앱결제 서비스
@MainActor
final class StoreService: ObservableObject {
    static let shared = StoreService()

    private nonisolated static let logger = Logger(
        subsystem: "com.teamentangle.focustimer",
        category: "StoreService"
    )

    /// 프리미엄 구독 상품
    @Published private(set) var premiumProduct: Product?
    /// 현재 프리미엄 구독 활성 여부
    @Published private(set) var isPremiumActive: Bool = false
    /// 구매 진행 중 여부
    @Published private(set) var isPurchasing: Bool = false

    private var transactionListener: Task<Void, Never>?

    private init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await updatePurchasedStatus()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - 상품 로드

    /// App Store Connect에서 상품 정보 로드
    func loadProducts() async {
        do {
            let products = try await Product.products(for: [StoreProduct.premiumMonthly])
            premiumProduct = products.first
        } catch {
            Self.logger.error("상품 로드 실패: \(error.localizedDescription)")
        }
    }

    // MARK: - 구매

    /// 프리미엄 구독 구매
    func purchasePremium() async -> Bool {
        guard let product = premiumProduct else {
            Self.logger.warning("구매 실패: 상품 정보 없음")
            return false
        }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await updatePurchasedStatus()
                Self.logger.info("프리미엄 구매 완료")
                return true

            case .userCancelled:
                Self.logger.info("사용자가 구매를 취소함")
                return false

            case .pending:
                Self.logger.info("구매 승인 대기 중")
                return false

            @unknown default:
                Self.logger.warning("알 수 없는 구매 결과")
                return false
            }
        } catch {
            Self.logger.error("구매 처리 실패: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - 구매 복원

    /// 이전 구매 복원
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updatePurchasedStatus()
            Self.logger.info("구매 복원 완료")
        } catch {
            Self.logger.error("구매 복원 실패: \(error.localizedDescription)")
        }
    }

    // MARK: - 구독 상태 확인

    /// 현재 구독 상태 업데이트
    func updatePurchasedStatus() async {
        var hasActiveSubscription = false

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.productID == StoreProduct.premiumMonthly,
                   transaction.revocationDate == nil {
                    hasActiveSubscription = true
                    break
                }
            } catch {
                Self.logger.error("구독 상태 확인 중 거래 검증 실패: \(error.localizedDescription)")
                continue
            }
        }

        isPremiumActive = hasActiveSubscription
    }

    // MARK: - Private

    /// 거래 검증
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }

    /// 백그라운드 거래 리스너 (자동 갱신, 환불 등 감지)
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self = self else { break }
                do {
                    let transaction = try await self.checkVerified(result)
                    await transaction.finish()
                    await self.updatePurchasedStatus()
                } catch {
                    // 검증 실패 거래는 finish() 호출하지 않음 — Apple이 재시도하도록 유지
                    Self.logger.error("거래 검증 실패 (finish 미호출): \(error.localizedDescription)")
                }
            }
        }
    }
}
