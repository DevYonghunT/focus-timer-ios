// ContentView.swift
// 메인 탭 바 뷰 — 타이머 / 통계 / 설정

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TimerView()
                .tabItem {
                    Label("타이머", systemImage: "timer")
                }

            StatisticsView()
                .tabItem {
                    Label("통계", systemImage: "chart.bar.fill")
                }

            SettingsView()
                .tabItem {
                    Label("설정", systemImage: "gearshape.fill")
                }
        }
        .tint(AppTheme.accent)
    }
}
