// StatisticsViewModel.swift
// 통계 뷰모델 — 일간/주간/월간 집중 시간 데이터 제공

import Foundation

/// 차트 데이터 포인트
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let label: String
    let focusMinutes: Double
}

/// 통계 뷰모델
@MainActor
final class StatisticsViewModel: ObservableObject {
    @Published var selectedPeriod: StatsPeriod = .daily
    @Published var chartData: [ChartDataPoint] = []
    @Published var totalFocusMinutes: Double = 0
    @Published var totalSessions: Int = 0
    @Published var averageFocusMinutes: Double = 0

    private let store = SessionStore.shared

    init() {
        refresh()
    }

    /// 선택된 기간에 맞춰 데이터 갱신
    func refresh() {
        switch selectedPeriod {
        case .daily:
            loadDailyData()
        case .weekly:
            loadWeeklyData()
        case .monthly:
            loadMonthlyData()
        }
    }

    /// 기간 변경 시 호출
    func changePeriod(to period: StatsPeriod) {
        selectedPeriod = period
        refresh()
    }

    // MARK: - 일간 (오늘 시간대별)

    private func loadDailyData() {
        let calendar = Calendar.current
        let today = Date()
        let sessions = store.sessions(for: today)
            .filter { $0.sessionType == .focus }

        // 시간대별 집계 (0시~23시)
        var hourlyMinutes: [Int: Double] = [:]
        for session in sessions {
            let hour = calendar.component(.hour, from: session.startedAt)
            hourlyMinutes[hour, default: 0] += Double(session.durationSeconds) / 60.0
        }

        // 현재 시각까지만 표시
        let currentHour = calendar.component(.hour, from: today)
        chartData = (0...currentHour).map { hour in
            ChartDataPoint(
                label: "\(hour)시",
                focusMinutes: hourlyMinutes[hour] ?? 0
            )
        }

        computeSummary(from: sessions)
    }

    // MARK: - 주간 (최근 7일)

    private func loadWeeklyData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekAgo = calendar.date(byAdding: .day, value: -6, to: today) ?? today

        let allSessions = store.sessions(from: weekAgo, to: Date())
            .filter { $0.sessionType == .focus }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "E"

        chartData = (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: weekAgo) ?? today
            let daySessions = allSessions.filter {
                calendar.isDate($0.startedAt, inSameDayAs: date)
            }
            let minutes = daySessions.reduce(0.0) {
                $0 + Double($1.durationSeconds) / 60.0
            }
            return ChartDataPoint(
                label: formatter.string(from: date),
                focusMinutes: minutes
            )
        }

        computeSummary(from: allSessions)
    }

    // MARK: - 월간 (최근 30일)

    private func loadMonthlyData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let monthAgo = calendar.date(byAdding: .day, value: -29, to: today) ?? today

        let allSessions = store.sessions(from: monthAgo, to: Date())
            .filter { $0.sessionType == .focus }

        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"

        // 5일 단위로 묶어서 표시 (가독성)
        var grouped: [ChartDataPoint] = []
        var offset = 0
        while offset < 30 {
            let rangeStart = calendar.date(byAdding: .day, value: offset, to: monthAgo) ?? today
            let rangeEnd = calendar.date(byAdding: .day, value: min(offset + 4, 29), to: monthAgo) ?? today

            let rangeSessions = allSessions.filter {
                let start = calendar.startOfDay(for: $0.startedAt)
                return start >= calendar.startOfDay(for: rangeStart)
                    && start <= calendar.startOfDay(for: rangeEnd)
            }
            let minutes = rangeSessions.reduce(0.0) {
                $0 + Double($1.durationSeconds) / 60.0
            }

            let label = formatter.string(from: rangeStart)
            grouped.append(ChartDataPoint(label: label, focusMinutes: minutes))
            offset += 5
        }

        chartData = grouped
        computeSummary(from: allSessions)
    }

    // MARK: - 요약 계산

    private func computeSummary(from sessions: [FocusSession]) {
        totalSessions = sessions.filter { $0.isCompleted }.count
        totalFocusMinutes = sessions.reduce(0.0) {
            $0 + Double($1.durationSeconds) / 60.0
        }
        let days = max(1, chartData.count)
        averageFocusMinutes = totalFocusMinutes / Double(days)
    }
}
