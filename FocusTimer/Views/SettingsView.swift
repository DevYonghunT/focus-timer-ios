// SettingsView.swift
// 설정 뷰 — 타이머 설정, 프리미엄 상태, 데이터 관리

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var timerVM: TimerViewModel
    @EnvironmentObject var storeService: StoreService
    @State private var showResetAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundDark
                    .ignoresSafeArea()

                List {
                    timerSettingsSection
                    generalSection
                    premiumSection
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
                unit: "분",
                isPremiumRequired: !settingsVM.isPremium && settingsVM.focusMinutes != 25
            )

            // 짧은 휴식
            StepperRow(
                title: "짧은 휴식",
                value: $settingsVM.shortBreakMinutes,
                range: 1...30,
                unit: "분",
                isPremiumRequired: !settingsVM.isPremium && settingsVM.shortBreakMinutes != 5
            )

            // 긴 휴식
            StepperRow(
                title: "긴 휴식",
                value: $settingsVM.longBreakMinutes,
                range: 1...60,
                unit: "분",
                isPremiumRequired: !settingsVM.isPremium && settingsVM.longBreakMinutes != 15
            )

            // 긴 휴식 간격
            StepperRow(
                title: "긴 휴식 간격",
                value: $settingsVM.longBreakInterval,
                range: 2...10,
                unit: "세션",
                isPremiumRequired: false
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

    // MARK: - 프리미엄 섹션

    private var premiumSection: some View {
        Section {
            if settingsVM.isPremium {
                HStack {
                    Label("프리미엄 활성화됨", systemImage: "crown.fill")
                        .foregroundColor(AppTheme.accent)
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.success)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundColor(AppTheme.accent)
                        Text("프리미엄으로 업그레이드")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        premiumFeatureRow("커스텀 타이머 시간 설정")
                        premiumFeatureRow("주간/월간 상세 통계")
                        premiumFeatureRow("추가 테마 컬러")
                    }
                    .padding(.top, 4)

                    // 구매 버튼
                    Button {
                        Task {
                            await storeService.purchasePremium()
                        }
                    } label: {
                        HStack {
                            if storeService.isPurchasing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(premiumPriceText)
                                    .font(.system(size: 15, weight: .bold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppTheme.accent)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(storeService.isPurchasing || storeService.premiumProduct == nil)
                    .padding(.top, 8)

                    // 구매 복원
                    Button {
                        Task {
                            await storeService.restorePurchases()
                        }
                    } label: {
                        Text("이전 구매 복원")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.secondaryText)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 4)
                }
            }
        } header: {
            Text("프리미엄")
                .foregroundColor(AppTheme.secondaryText)
        }
        .listRowBackground(AppTheme.surface)
    }

    /// 프리미엄 가격 텍스트 (상품 로드 전에는 기본값 표시)
    private var premiumPriceText: String {
        if let product = storeService.premiumProduct {
            return "프리미엄 구독 — \(product.displayPrice)/월"
        }
        return "프리미엄 구독"
    }

    private func premiumFeatureRow(_ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(AppTheme.accent)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.secondaryText)
        }
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
    let isPremiumRequired: Bool

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.white)

            Spacer()

            if isPremiumRequired {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.secondaryText)
            }

            Text("\(value) \(unit)")
                .foregroundColor(AppTheme.accent)
                .font(.system(size: 15, weight: .medium))

            Stepper("", value: $value, in: range)
                .labelsHidden()
                .tint(AppTheme.accent)
                .disabled(isPremiumRequired)
        }
    }
}
