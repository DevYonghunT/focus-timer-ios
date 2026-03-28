// StatisticsViewModelTests.swift
// StatisticsViewModel 테스트 — 통계 데이터 집계, 기간 필터, 요약 계산 검증

import XCTest
@testable import FocusTimer

@MainActor
final class StatisticsViewModelTests: XCTestCase {

    private var sut: StatisticsViewModel!
    private let store = SessionStore.shared

    override func setUp() {
        super.setUp()
        store.clearAll()
        sut = StatisticsViewModel()
    }

    override func tearDown() {
        sut = nil
        store.clearAll()
        super.tearDown()
    }

    // MARK: - νₑ 정상 경로 (Happy Path)

    func test_init_defaultPeriod_isDaily() {
        XCTAssertEqual(sut.selectedPeriod, .daily)
    }

    func test_changePeriod_toWeekly_updatesPeriodAndData() {
        // Act
        sut.changePeriod(to: .weekly)

        // Assert
        XCTAssertEqual(sut.selectedPeriod, .weekly)
        XCTAssertEqual(sut.chartData.count, 7) // 최근 7일
    }

    func test_changePeriod_toMonthly_updatesPeriodAndData() {
        // Act
        sut.changePeriod(to: .monthly)

        // Assert
        XCTAssertEqual(sut.selectedPeriod, .monthly)
        XCTAssertEqual(sut.chartData.count, 6) // 30일 / 5일 단위 = 6그룹
    }

    func test_daily_withSessions_calculatesCorrectTotal() {
        // Arrange
        store.save(session: FocusSession(
            durationSeconds: 1500, sessionType: .focus, isCompleted: true
        ))
        store.save(session: FocusSession(
            durationSeconds: 900, sessionType: .focus, isCompleted: true
        ))

        // Act
        sut.refresh()

        // Assert
        XCTAssertEqual(sut.totalFocusMinutes, 40.0, accuracy: 0.1) // (1500+900)/60
        XCTAssertEqual(sut.totalSessions, 2)
    }

    func test_daily_onlyFocusSessions_excludesBreaks() {
        // Arrange
        store.save(session: FocusSession(
            durationSeconds: 1500, sessionType: .focus, isCompleted: true
        ))
        store.save(session: FocusSession(
            durationSeconds: 300, sessionType: .shortBreak, isCompleted: true
        ))

        // Act
        sut.refresh()

        // Assert
        XCTAssertEqual(sut.totalFocusMinutes, 25.0, accuracy: 0.1)
    }

    func test_weekly_chartData_hasSeven() {
        // Arrange
        sut.changePeriod(to: .weekly)

        // Assert
        XCTAssertEqual(sut.chartData.count, 7)
    }

    func test_monthly_chartData_hasSixGroups() {
        // Arrange
        sut.changePeriod(to: .monthly)

        // Assert — 30일 / 5일 단위 = 6그룹
        XCTAssertEqual(sut.chartData.count, 6)
    }

    func test_totalSessions_countsOnlyCompleted() {
        // Arrange
        store.save(session: FocusSession(
            durationSeconds: 1500, sessionType: .focus, isCompleted: true
        ))
        store.save(session: FocusSession(
            durationSeconds: 800, sessionType: .focus, isCompleted: false
        ))

        // Act
        sut.refresh()

        // Assert
        XCTAssertEqual(sut.totalSessions, 1) // 완료된 것만
        XCTAssertEqual(sut.totalFocusMinutes, (1500.0 + 800.0) / 60.0, accuracy: 0.1) // 시간은 모두 포함
    }

    func test_averageFocusMinutes_calculatedCorrectly() {
        // Arrange
        store.save(session: FocusSession(
            durationSeconds: 1500, sessionType: .focus, isCompleted: true
        ))

        // Act
        sut.changePeriod(to: .weekly)

        // Assert — 1500초 / 60 = 25분, 7일 평균 = 25/7
        let expected = 25.0 / 7.0
        XCTAssertEqual(sut.averageFocusMinutes, expected, accuracy: 0.1)
    }

    // MARK: - νμ 예외 경로 (Error Path)

    func test_noSessions_allZeros() {
        // Act
        sut.refresh()

        // Assert
        XCTAssertEqual(sut.totalFocusMinutes, 0)
        XCTAssertEqual(sut.totalSessions, 0)
        XCTAssertEqual(sut.averageFocusMinutes, 0)
    }

    func test_noSessions_weekly_chartDataAllZero() {
        // Act
        sut.changePeriod(to: .weekly)

        // Assert
        XCTAssertEqual(sut.chartData.count, 7)
        for point in sut.chartData {
            XCTAssertEqual(point.focusMinutes, 0)
        }
    }

    func test_noSessions_monthly_chartDataAllZero() {
        // Act
        sut.changePeriod(to: .monthly)

        // Assert
        for point in sut.chartData {
            XCTAssertEqual(point.focusMinutes, 0)
        }
    }

    // MARK: - ντ 경계 경로 (Edge Case)

    func test_daily_chartData_hourLabelsUpToCurrentHour() {
        // Act
        sut.changePeriod(to: .daily)

        // Assert — 0시부터 현재 시각까지
        let currentHour = Calendar.current.component(.hour, from: Date())
        XCTAssertEqual(sut.chartData.count, currentHour + 1)
    }

    func test_changePeriod_rapidSwitch_noError() {
        // Act — 빠르게 기간 전환
        for _ in 0..<20 {
            sut.changePeriod(to: .daily)
            sut.changePeriod(to: .weekly)
            sut.changePeriod(to: .monthly)
        }

        // Assert — 마지막 설정이 반영
        XCTAssertEqual(sut.selectedPeriod, .monthly)
    }

    func test_chartDataPoint_identifiable_uniqueIDs() {
        // Arrange
        sut.changePeriod(to: .weekly)

        // Assert
        let ids = Set(sut.chartData.map { $0.id })
        XCTAssertEqual(ids.count, sut.chartData.count)
    }

    func test_manySessions_performsWithinReasonableTime() {
        // Arrange — 많은 세션 추가
        for i in 0..<500 {
            store.save(session: FocusSession(
                durationSeconds: (i % 30 + 1) * 60,
                sessionType: .focus,
                isCompleted: i % 3 != 0
            ))
        }

        // Act & Assert — 1초 이내 완료
        let start = Date()
        sut.refresh()
        let elapsed = Date().timeIntervalSince(start)
        XCTAssertLessThan(elapsed, 1.0)
    }

    func test_weeklyData_sessionSpreadAcrossDays_correctDayTotals() {
        // Arrange
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // 오늘과 3일 전에 세션 추가
        store.save(session: FocusSession(
            startedAt: today,
            durationSeconds: 1500,
            sessionType: .focus,
            isCompleted: true
        ))

        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!
        store.save(session: FocusSession(
            startedAt: threeDaysAgo,
            durationSeconds: 900,
            sessionType: .focus,
            isCompleted: true
        ))

        // Act
        sut.changePeriod(to: .weekly)

        // Assert — 총 분 확인
        XCTAssertEqual(sut.totalFocusMinutes, (1500.0 + 900.0) / 60.0, accuracy: 0.1)
    }

    func test_statsPeriod_allCases_hasDailyWeeklyMonthly() {
        let allCases = StatsPeriod.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.daily))
        XCTAssertTrue(allCases.contains(.weekly))
        XCTAssertTrue(allCases.contains(.monthly))
    }

    func test_statsPeriod_rawValues_korean() {
        XCTAssertEqual(StatsPeriod.daily.rawValue, "일간")
        XCTAssertEqual(StatsPeriod.weekly.rawValue, "주간")
        XCTAssertEqual(StatsPeriod.monthly.rawValue, "월간")
    }
}
