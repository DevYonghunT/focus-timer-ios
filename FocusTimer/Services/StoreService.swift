// StoreService.swift
// 프리미엄 상태 제공 — StoreKit 제거, 모든 기능 무료 해금

import Foundation

/// 프리미엄 상태 제공 (모든 기능 무료 해금)
@MainActor
final class StoreService: ObservableObject {
    static let shared = StoreService()

    /// 프리미엄 항상 활성
    @Published private(set) var isPremiumActive: Bool = true

    private init() {}
}
