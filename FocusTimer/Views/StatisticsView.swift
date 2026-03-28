// StatisticsView.swift
// 통계 뷰 — Swift Charts로 집중 시간 시각화

import SwiftUI
import Charts

struct StatisticsView: View {
    @EnvironmentObject var statsVM: StatisticsViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundDark
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        periodPicker
                        summaryCards
                        chartSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("통계")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear { statsVM.refresh() }
        }
    }

    // MARK: - 기간 선택 피커

    private var periodPicker: some View {
        HStack(spacing: 0) {
            ForEach(StatsPeriod.allCases, id: \.self) { period in
                let isSelected = statsVM.selectedPeriod == period
                // 프리미엄 잠금 여부
                let isLocked = !settingsVM.isPremium && period != .daily

                Button(action: {
                    guard !isLocked else { return }
                    statsVM.changePeriod(to: period)
                }) {
                    HStack(spacing: 4) {
                        Text(period.rawValue)
                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10))
                        }
                    }
                    .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .white : AppTheme.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isSelected ? AppTheme.accent : Color.clear)
                    )
                }
                .disabled(isLocked)
                .opacity(isLocked ? 0.5 : 1.0)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppTheme.surface)
        )
    }

    // MARK: - 요약 카드

    private var summaryCards: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "총 집중",
                value: formatMinutes(statsVM.totalFocusMinutes),
                icon: "flame.fill",
                color: AppTheme.accent
            )

            StatCard(
                title: "완료 세션",
                value: "\(statsVM.totalSessions)",
                icon: "checkmark.circle.fill",
                color: AppTheme.success
            )

            StatCard(
                title: "일 평균",
                value: formatMinutes(statsVM.averageFocusMinutes),
                icon: "chart.line.uptrend.xyaxis",
                color: AppTheme.breakColor
            )
        }
    }

    // MARK: - 차트 영역

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("집중 시간 추이")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            if statsVM.chartData.isEmpty || statsVM.chartData.allSatisfy({ $0.focusMinutes == 0 }) {
                emptyChartPlaceholder
            } else {
                chartContent
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.surface)
        )
    }

    private var chartContent: some View {
        Chart(statsVM.chartData) { point in
            BarMark(
                x: .value("기간", point.label),
                y: .value("분", point.focusMinutes)
            )
            .foregroundStyle(AppTheme.accent.gradient)
            .cornerRadius(4)
        }
        .chartYAxisLabel("분")
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                    .foregroundStyle(Color.white.opacity(0.1))
                AxisValueLabel()
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel()
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .frame(height: 220)
    }

    private var emptyChartPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.secondaryText.opacity(0.5))
            Text("아직 기록이 없어요")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
    }

    // MARK: - 유틸리티

    private func formatMinutes(_ minutes: Double) -> String {
        if minutes >= 60 {
            let hours = Int(minutes) / 60
            let remaining = Int(minutes) % 60
            return "\(hours)h \(remaining)m"
        }
        return "\(Int(minutes))m"
    }
}

// MARK: - 요약 카드 컴포넌트

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.system(size: 11))
                .foregroundColor(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
