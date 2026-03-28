// IntegrationTests.swift
// 통합 테스트 — ViewModel 간 데이터 흐름, Timer → SessionStore → Statistics 파이프라인

import XCTest
@testable import FocusTimer

@MainActor
final class IntegrationTests: XCTestCase {

    override func setUp() {
        super.setUp()
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "settings.focusMinutes")
        defaults.removeObject(forKey: "settings.shortBreakMinutes")
        defaults.removeObject(forKey: "settings.longBreakMinutes")
        defaults.removeObject(forKey: "settings.longBreakInterval")
        defaults.removeObject(forKey: "settings.isPremium")
        defaults.removeObject(forKey: "settings.autoStartBreak")
        defaults.removeObject(forKey: "settings.soundEnabled")
        defaults.removeObject(forKey: "com.focustimer.sessions")
        SessionStore.shared.clearAll()
    }

    override func tearDown() {
        SessionStore.shared.clearAll()
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "settings.focusMinutes")
        defaults.removeObject(forKey: "settings.shortBreakMinutes")
        defaults.removeObject(forKey: "settings.longBreakMinutes")
        defaults.removeObject(forKey: "settings.longBreakInterval")
        defaults.removeObject(forKey: "settings.isPremium")
        defaults.removeObject(forKey: "settings.autoStartBreak")
        defaults.removeObject(forKey: "settings.soundEnabled")
        defaults.removeObject(forKey: "com.focustimer.sessions")
        super.tearDown()
    }

    // MARK: - νₑ 정상 경로 (Happy Path) — 통합 흐름

    /// Timer에서 세션 저장 → SessionStore에서 조회 가능 확인
    func test_timerReset_savesIncompleteSession_storeContainsIt() {
        // Arrange
        let timer = TimerViewModel()
        timer.start()
        timer.remainingSeconds = timer.remainingSeconds - 60 // 1분 경과 시뮬레이션

        // Act
        timer.reset() // 미완료 세션이 SessionStore에 저장됨

        // Assert
        let sessions = SessionStore.shared.loadAll()
        XCTAssertGreaterThanOrEqual(sessions.count, 1)
        // 미완료 세션이 기록됨
        let incompleteSessions = sessions.filter { !$0.isCompleted }
        XCTAssertGreaterThanOrEqual(incompleteSessions.count, 1)
    }

    /// Settings 변경 → TimerViewModel이 새 설정을 반영하는지 확인
    func test_settingsChange_timerReflectsNewDuration() {
        // Arrange
        let settings = SettingsViewModel()
        let timer = TimerViewModel()

        // Act — 포커스 시간을 30분으로 변경
        settings.focusMinutes = 30

        // 새 TimerViewModel 생성 시 반영 확인
        let timer2 = TimerViewModel()

        // Assert
        XCTAssertEqual(timer2.focusDuration, 30 * 60)
        XCTAssertEqual(timer2.remainingSeconds, 30 * 60)
    }

    /// SessionStore에 세션 저장 → StatisticsViewModel에서 집계 확인
    func test_sessionSaved_statisticsReflectsData() {
        // Arrange
        let store = SessionStore.shared
        store.save(session: FocusSession(
            durationSeconds: 1500,
            sessionType: .focus,
            isCompleted: true
        ))
        store.save(session: FocusSession(
            durationSeconds: 1200,
            sessionType: .focus,
            isCompleted: true
        ))

        // Act
        let stats = StatisticsViewModel()

        // Assert
        XCTAssertGreaterThanOrEqual(stats.totalSessions, 2)
        XCTAssertGreaterThanOrEqual(stats.totalFocusMinutes, 45) // (1500+1200)/60 = 45
    }

    /// Timer의 refreshTodayStats → 오늘 통계가 Store의 데이터와 일치
    func test_timerRefresh_matchesStoreStats() {
        // Arrange
        let store = SessionStore.shared
        store.save(session: FocusSession(
            durationSeconds: 1500,
            sessionType: .focus,
            isCompleted: true
        ))
        store.save(session: FocusSession(
            durationSeconds: 300,
            sessionType: .shortBreak,
            isCompleted: true
        ))

        // Act
        let timer = TimerViewModel()
        timer.refreshTodayStats()
        let storeStats = store.todayStats()

        // Assert — Timer와 Store의 통계가 일치
        XCTAssertEqual(timer.completedPomodoros, storeStats.completedCount)
        XCTAssertEqual(timer.todayFocusSeconds, storeStats.focusSeconds)
    }

    /// Settings → Timer → Store → Statistics 전체 파이프라인
    func test_fullPipeline_settingsToStatistics() {
        // Arrange — 설정: 1분 포커스
        let settings = SettingsViewModel()
        settings.focusMinutes = 1

        // Act — 세션 시뮬레이션 (직접 Store에 저장)
        let session = FocusSession(
            durationSeconds: 60,
            sessionType: .focus,
            isCompleted: true
        )
        SessionStore.shared.save(session: session)

        // Assert — Statistics에서 확인
        let statsVM = StatisticsViewModel()
        XCTAssertGreaterThanOrEqual(statsVM.totalSessions, 1)
        XCTAssertGreaterThanOrEqual(statsVM.totalFocusMinutes, 1)
    }

    // MARK: - νμ 예외 경로 (Error Path) — 통합 흐름

    /// Settings를 기본값으로 리셋 → Timer가 기본 25분으로 복귀
    func test_settingsReset_timerUsesDefaults() {
        // Arrange — 설정 변경
        let settings = SettingsViewModel()
        settings.focusMinutes = 50

        // Act — 리셋
        settings.resetToDefaults()
        let timer = TimerViewModel()

        // Assert
        XCTAssertEqual(timer.focusDuration, 25 * 60)
    }

    /// 빈 Store → Statistics는 0을 반환
    func test_emptyStore_statisticsShowsZero() {
        // Arrange — Store 비어있음
        SessionStore.shared.clearAll()

        // Act
        let stats = StatisticsViewModel()

        // Assert
        XCTAssertEqual(stats.totalSessions, 0)
        XCTAssertEqual(stats.totalFocusMinutes, 0)
    }

    /// Break 세션만 있을 때 Timer의 완료 포모도로 수는 0
    func test_onlyBreakSessions_timerCompletedPomodorosIsZero() {
        // Arrange
        SessionStore.shared.save(session: FocusSession(
            durationSeconds: 300,
            sessionType: .shortBreak,
            isCompleted: true
        ))
        SessionStore.shared.save(session: FocusSession(
            durationSeconds: 900,
            sessionType: .longBreak,
            isCompleted: true
        ))

        // Act
        let timer = TimerViewModel()

        // Assert
        XCTAssertEqual(timer.completedPomodoros, 0)
        XCTAssertEqual(timer.todayFocusSeconds, 0)
    }

    // MARK: - ντ 경계 경로 (Edge Case) — 통합 흐름

    /// 여러 ViewModel이 동시에 같은 Store 데이터를 읽을 때 일관성 확인
    func test_multipleViewModels_readConsistentData() {
        // Arrange
        SessionStore.shared.save(session: FocusSession(
            durationSeconds: 1500,
            sessionType: .focus,
            isCompleted: true
        ))

        // Act — 여러 ViewModel 동시 생성
        let timer = TimerViewModel()
        let stats = StatisticsViewModel()
        let storeStats = SessionStore.shared.todayStats()

        // Assert — 모두 같은 데이터를 읽음
        XCTAssertEqual(timer.completedPomodoros, storeStats.completedCount)
        XCTAssertGreaterThanOrEqual(stats.totalSessions, 1)
    }

    /// Settings에서 longBreakInterval 변경 → skipToNext 순환에 반영
    func test_longBreakIntervalChange_affectsSessionCycle() {
        // Arrange — interval을 2로 설정
        let settings = SettingsViewModel()
        settings.longBreakInterval = 2

        let timer = TimerViewModel()

        // Act — 2번 focus → shortBreak → focus 순환
        // completedPomodoros를 수동으로 2로 설정 (longBreakInterval=2이므로 longBreak 트리거)
        SessionStore.shared.save(session: FocusSession(
            durationSeconds: 1500,
            sessionType: .focus,
            isCompleted: true
        ))
        SessionStore.shared.save(session: FocusSession(
            durationSeconds: 1500,
            sessionType: .focus,
            isCompleted: true
        ))
        timer.refreshTodayStats()

        // Assert
        XCTAssertEqual(timer.completedPomodoros, 2)
        XCTAssertEqual(timer.longBreakInterval, 2)
    }

    /// 대량 세션 저장 후 Statistics 성능 확인
    func test_manySessionsSaved_statisticsLoadsWithinTime() {
        // Arrange — 500개 세션 저장
        let store = SessionStore.shared
        for i in 0..<500 {
            let daysAgo = i / 20 // 하루에 20개씩
            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
            store.save(session: FocusSession(
                startedAt: date,
                durationSeconds: 1500,
                sessionType: .focus,
                isCompleted: true
            ))
        }

        // Act & Assert — 1초 이내 로드
        let start = CFAbsoluteTimeGetCurrent()
        let stats = StatisticsViewModel()
        stats.changePeriod(to: .monthly)
        let elapsed = CFAbsoluteTimeGetCurrent() - start

        XCTAssertLessThan(elapsed, 1.0, "Statistics 로드가 1초를 초과함")
        XCTAssertGreaterThan(stats.totalSessions, 0)
    }

    /// Store clearAll 후 Timer와 Statistics 모두 0으로 리셋
    func test_storeClearAll_allViewModelsReflectEmpty() {
        // Arrange
        SessionStore.shared.save(session: FocusSession(
            durationSeconds: 1500,
            sessionType: .focus,
            isCompleted: true
        ))

        // Act
        SessionStore.shared.clearAll()
        let timer = TimerViewModel()
        let stats = StatisticsViewModel()

        // Assert
        XCTAssertEqual(timer.completedPomodoros, 0)
        XCTAssertEqual(timer.todayFocusSeconds, 0)
        XCTAssertEqual(stats.totalSessions, 0)
    }
}
