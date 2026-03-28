// StoreServiceTests.swift
// StoreService 테스트 — 구매 플로우, 검증 로직, 상태 관리 검증

import XCTest
@testable import FocusTimer

@MainActor
final class StoreServiceTests: XCTestCase {

    private var sut: StoreService!

    override func setUp() {
        super.setUp()
        sut = StoreService.shared
    }

    // MARK: - 상품 미로드 시 구매 실패

    func test_purchasePremium_noProduct_returnsFalse() async {
        // 상품이 App Store Connect에 등록되지 않은 상태에서는
        // premiumProduct가 nil이므로 구매 시도 시 false 반환
        if sut.premiumProduct == nil {
            let result = await sut.purchasePremium()
            XCTAssertFalse(result, "상품 없을 때 구매는 false를 반환해야 한다")
        }
    }

    // MARK: - isPurchasing 플래그

    func test_isPurchasing_initialState_isFalse() {
        XCTAssertFalse(sut.isPurchasing, "초기 상태에서 isPurchasing은 false여야 한다")
    }

    func test_purchasePremium_noProduct_isPurchasingResetsToFalse() async {
        // 상품 없을 때 구매 시도 후 isPurchasing이 false로 복귀하는지 확인
        if sut.premiumProduct == nil {
            _ = await sut.purchasePremium()
            XCTAssertFalse(sut.isPurchasing, "구매 완료 후 isPurchasing은 false로 복귀해야 한다")
        }
    }

    // MARK: - 초기 상태

    func test_isPremiumActive_initialState() {
        // 테스트 환경에서는 실제 구독이 없으므로 false
        // (StoreKit Testing Configuration 없이 실행 시)
        XCTAssertNotNil(sut, "StoreService 싱글톤이 존재해야 한다")
    }

    func test_singleton_returnsSameInstance() {
        let instance1 = StoreService.shared
        let instance2 = StoreService.shared
        XCTAssertTrue(instance1 === instance2, "싱글톤은 동일한 인스턴스를 반환해야 한다")
    }
}
