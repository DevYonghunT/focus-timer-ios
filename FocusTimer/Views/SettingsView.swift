// SettingsView.swift
// 설정 뷰 — 타이머 설정, 데이터 관리 (모든 기능 무료 해금)

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var timerVM: TimerViewModel
    @State private var showResetAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundDark
                    .ignoresSafeArea()

                List {
                    timerSettingsSection
                    generalSection
                    dataSection
                    aboutSection
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("기록 초기화", isPresented: $showResetAlert) {
                Button("취소", role: .cancel) {}
                Button("초기화", role: .destructive) {
                    SessionStore.shared.clearAll()
                    timerVM.refreshTodayStats()
                }
            } message: {
                Text("모든 집중 기록이 삭제됩니다. 되돌릴 수 없습니다.")
            }
        }
    }

    // MARK: - 타이머 설정 섹션

    private var timerSettingsSection: some View {
        Section {
            // 집중 시간
            StepperRow(
                title: "집중 시간",
                value: $settingsVM.focusMinutes,
                range: 1...120,
                unit: "분"
            )

            // 짧은 휴식
            StepperRow(
                title: "짧은 휴식",
                value: $settingsVM.shortBreakMinutes,
                range: 1...30,
                unit: "분"
            )

            // 긴 휴식
            StepperRow(
                title: "긴 휴식",
                value: $settingsVM.longBreakMinutes,
                range: 1...60,
                unit: "분"
            )

            // 긴 휴식 간격
            StepperRow(
                title: "긴 휴식 간격",
                value: $settingsVM.longBreakInterval,
                range: 2...10,
                unit: "세션"
            )
        } header: {
            Text("타이머")
                .foregroundColor(AppTheme.secondaryText)
        }
        .listRowBackground(AppTheme.surface)
    }

    // MARK: - 일반 설정 섹션

    private var generalSection: some View {
        Section {
            Toggle(isOn: $settingsVM.soundEnabled) {
                Label("소리 알림", systemImage: "speaker.wave.2.fill")
                    .foregroundColor(.white)
            }
            .tint(AppTheme.accent)
        } header: {
            Text("일반")
                .foregroundColor(AppTheme.secondaryText)
        }
        .listRowBackground(AppTheme.surface)
    }

    // MARK: - 데이터 관리 섹션

    private var dataSection: some View {
        Section {
            Button(action: { settingsVM.resetToDefaults() }) {
                Label("설정 초기화", systemImage: "arrow.counterclockwise")
                    .foregroundColor(.white)
            }

            Button(action: { showResetAlert = true }) {
                Label("기록 전체 삭제", systemImage: "trash.fill")
                    .foregroundColor(.red)
            }
        } header: {
            Text("데이터")
                .foregroundColor(AppTheme.secondaryText)
        }
        .listRowBackground(AppTheme.surface)
    }

    // MARK: - 앱 정보 섹션

    private var aboutSection: some View {
        Section {
            HStack {
                Text("버전")
                    .foregroundColor(.white)
                Spacer()
                Text("1.0.0")
                    .foregroundColor(AppTheme.secondaryText)
            }
        } header: {
            Text("정보")
                .foregroundColor(AppTheme.secondaryText)
        }
        .listRowBackground(AppTheme.surface)
    }
}

// MARK: - 스텝퍼 행 컴포넌트

struct StepperRow: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.white)

            Spacer()

            Text("\(value) \(unit)")
                .foregroundColor(AppTheme.accent)
                .font(.system(size: 15, weight: .medium))

            Stepper("", value: $value, in: range)
                .labelsHidden()
                .tint(AppTheme.accent)
        }
    }
}
