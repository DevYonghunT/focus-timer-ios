// AppLogger.swift
// 앱 전역 로거 — os.Logger 기반

import Foundation
import os

/// 앱 전역 로거 (카테고리별 분리)
enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.teamentangle.focustimer"

    /// 타이머 관련 로그
    static let timer = Logger(subsystem: subsystem, category: "Timer")
    /// 데이터 저장 관련 로그
    static let store = Logger(subsystem: subsystem, category: "Store")
    /// 알림 관련 로그
    static let notification = Logger(subsystem: subsystem, category: "Notification")
}
