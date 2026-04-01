// FocusTimerApp.swift
// 앱 진입점 — 탭 기반 네비게이션 구성

import SwiftUI
import UserNotifications
import os

@main
struct FocusTimerApp: App {
    @StateObject private var timerVM = TimerViewModel()
    @StateObject private var statsVM = StatisticsViewModel()
    @StateObject private var settingsVM = SettingsViewModel()

    init() {
        // 알림 권한 요청
        requestNotificationPermission()
        configureAppearance()
    }

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(timerVM)
                .environmentObject(statsVM)
                .environmentObject(settingsVM)
                .preferredColorScheme(.dark)
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                timerVM.handleBackgroundTransition()
            case .active:
                timerVM.handleForegroundTransition()
            default:
                break
            }
        }
    }

    /// 로컬 알림 권한 요청
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if let error = error {
                AppLogger.notification.error("알림 권한 요청 실패: \(error.localizedDescription)")
            }
        }
    }

    /// 전역 UI 외형 설정
    private func configureAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppTheme.backgroundDark)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
