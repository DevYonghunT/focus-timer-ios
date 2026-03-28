// AppTheme.swift
// 앱 전역 테마 상수 — 다크 테마 + 네온 퍼플 액센트

import SwiftUI

enum AppTheme {
    /// 네온 퍼플 액센트 컬러 (#8B5CF6)
    static let accent = Color(red: 139/255, green: 92/255, blue: 246/255)

    /// 메인 배경 (깊은 다크)
    static let backgroundDark = Color(red: 13/255, green: 13/255, blue: 20/255)

    /// 카드/서피스 배경
    static let surface = Color(red: 24/255, green: 24/255, blue: 35/255)

    /// 보조 텍스트 컬러
    static let secondaryText = Color(red: 156/255, green: 163/255, blue: 175/255)

    /// 성공/완료 컬러
    static let success = Color(red: 34/255, green: 197/255, blue: 94/255)

    /// 휴식 모드 컬러
    static let breakColor = Color(red: 59/255, green: 130/255, blue: 246/255)

    /// 프로그레스 링 배경 트랙
    static let trackColor = Color.white.opacity(0.08)

    /// 액센트 그라데이션 (링 등에 사용)
    static let accentGradient = LinearGradient(
        colors: [accent, Color(red: 168/255, green: 85/255, blue: 247/255)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
