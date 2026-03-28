// SessionStoreTests.swift
// SessionStore 테스트 — 세션 저장, 조회, 필터링, 통계 검증

import XCTest
@testable import FocusTimer

final class SessionStoreTests: XCTestCase {

    private let store = SessionStore.shared

    override func setUp() {
        super.setUp()
        store.clearAll()
    }

    override func tearDown() {
        store.clearAll()
        super.tearDown()
    }

    // MARK: - νₑ 정상 경로 (Happy Path)

    func test_save_singleSession_loadAllReturnsOne() {
        // Arrange
        let session = FocusSession(
            durationSeconds: 1500,
            sessionType: .focus,
            isCompleted: true
        )

        // Act
        store.save(session: session)
        let loaded = store.loadAll()

        // Assert
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.id, session.id)
        XCTAssertEqual(loaded.first?.durationSeconds, 1500)
    }

    func test_save_multipleSessions_loadAllReturnsAll() {
        // Arrange & Act
        for i in 1...5 {
            let session = FocusSession(
                durationSeconds: i * 300,
                sessionType: .focus,
                isCompleted: true
            )
            store.save(session: session)
        }
        let loaded = store.loadAll()

        // Assert
        XCTAssertEqual(loaded.count, 5)
    }

    func test_clearAll_afterSaving_loadAllReturnsEmpty() {
        // Arrange
        store.save(session: FocusSession(
            durationSeconds: 1500, sessionType: .focus, isCompleted: true
        ))
        XCTAssertEqual(store.loadAll().count, 1)

        // Act
        store.clearAll()

        // Assert
        XCTAssertEqual(store.loadAll().count, 0)
    }

    func test_sessionsForDate_today_returnsOnlyTodaySessions() {
        // Arrange
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        let todaySession = FocusSession(
            startedAt: today,
            durationSeconds: 1500,
            sessionType: .focus,
            isCompleted: true
        )
        let yesterdaySession = FocusSession(
            startedAt: yesterday,
            durationSeconds: 1500,
            sessionType: .focus,
            isCompleted: true
        )

        // Act
        store.save(session: todaySession)
        store.save(session: yesterdaySession)
        let todaySessions = store.sessions(for: today)

        // Assert
        XCTAssertEqual(todaySessions.count, 1)
        XCTAssertEqual(todaySessions.first?.id, todaySession.id)
    }

    func test_sessionsFromTo_dateRange_returnsCorrectSessions() {
        // Arrange
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!
        let fiveDaysAgo = calendar.date(byAdding: .day, value: -5, to: today)!

        let recentSession = FocusSession(
            startedAt: today,
            durationSeconds: 1500,
            sessionType: .focus,
            isCompleted: true
        )
        let oldSession = FocusSession(
            startedAt: fiveDaysAgo,
            durationSeconds: 1500,
            sessionType: .focus,
            isCompleted: true
        )

        store.save(session: recentSession)
        store.save(session: oldSession)

        // Act
        let rangedSessions = store.sessions(from: threeDaysAgo, to: today)

        // Assert
        XCTAssertEqual(rangedSessions.count, 1)
        XCTAssertEqual(rangedSessions.first?.id, recentSession.id)
    }

    func test_todayStats_multipleFocusSessions_returnsCorrectCounts() {
        // Arrange
        store.save(session: FocusSession(
            durationSeconds: 1500, sessionType: .focus, isCompleted: true
        ))
        store.save(session: FocusSession(
            durationSeconds: 1200, sessionType: .focus, isCompleted: true
        ))
        store.save(session: FocusSession(
            durationSeconds: 800, sessionType: .focus, isCompleted: false
        ))
        // 휴식 세션은 카운트에서 제외되어야 함
        store.save(session: FocusSession(
            durationSeconds: 300, sessionType: .shortBreak, isCompleted: true
        ))

        // Act
        let stats = store.todayStats()

        // Assert
        XCTAssertEqual(stats.completedCount, 2) // 완료된 focus만
        XCTAssertEqual(stats.focusSeconds, 1500 + 1200 + 800) // 모든 focus 세션 합산
    }

    func test_todayCompletedCount_matchesTodayStatsCompletedCount() {
        // Arrange
        store.save(session: FocusSession(
            durationSeconds: 1500, sessionType: .focus, isCompleted: true
        ))
        store.save(session: FocusSession(
            durationSeconds: 1500, sessionType: .focus, isCompleted: false
        ))

        // Act & Assert
        let stats = store.todayStats()
        let legacyCount = store.todayCompletedCount()
        XCTAssertEqual(stats.completedCount, legacyCount)
    }

    func test_todayFocusSeconds_matchesTodayStatsFocusSeconds() {
        // Arrange
        store.save(session: FocusSession(
            durationSeconds: 1500, sessionType: .focus, isCompleted: true
        ))
        store.save(session: FocusSession(
            durationSeconds: 900, sessionType: .focus, isCompleted: false
        ))

        // Act & Assert
        let stats = store.todayStats()
        let legacySeconds = store.todayFocusSeconds()
        XCTAssertEqual(stats.focusSeconds, legacySeconds)
    }

    // MARK: - νμ 예외 경로 (Error Path)

    func test_loadAll_noData_returnsEmptyArray() {
        // Act
        let sessions = store.loadAll()

        // Assert
        XCTAssertTrue(sessions.isEmpty)
    }

    func test_sessionsForDate_noMatchingDate_returnsEmpty() {
        // Arrange
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        store.save(session: FocusSession(
            startedAt: yesterday,
            durationSeconds: 1500,
            sessionType: .focus,
            isCompleted: true
        ))

        // Act
        let todaySessions = store.sessions(for: Date())

        // Assert
        XCTAssertTrue(todaySessions.isEmpty)
    }

    func test_todayStats_noSessions_returnsZeros() {
        // Act
        let stats = store.todayStats()

        // Assert
        XCTAssertEqual(stats.completedCount, 0)
        XCTAssertEqual(stats.focusSeconds, 0)
    }

    func test_todayStats_onlyBreakSessions_returnsZeros() {
        // Arrange
        store.save(session: FocusSession(
            durationSeconds: 300, sessionType: .shortBreak, isCompleted: true
        ))
        store.save(session: FocusSession(
            durationSeconds: 900, sessionType: .longBreak, isCompleted: true
        ))

        // Act
        let stats = store.todayStats()

        // Assert
        XCTAssertEqual(stats.completedCount, 0)
        XCTAssertEqual(stats.focusSeconds, 0)
    }

    // MARK: - ντ 경계 경로 (Edge Case)

    func test_save_manySessions_allPersisted() {
        // Arrange & Act
        for i in 0..<200 {
            store.save(session: FocusSession(
                durationSeconds: i,
                sessionType: .focus,
                isCompleted: true
            ))
        }

        // Assert
        let loaded = store.loadAll()
        XCTAssertEqual(loaded.count, 200)
    }

    func test_sessionsFromTo_sameDateRange_returnsSessionsOnThatDate() {
        // Arrange
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: today)!

        store.save(session: FocusSession(
            startedAt: today,
            durationSeconds: 1500,
            sessionType: .focus,
            isCompleted: true
        ))

        // Act
        let sessions = store.sessions(from: today, to: endOfToday)

        // Assert
        XCTAssertEqual(sessions.count, 1)
    }

    func test_clearAll_calledTwice_noError() {
        // Arrange
        store.save(session: FocusSession(
            durationSeconds: 1500, sessionType: .focus, isCompleted: true
        ))

        // Act & Assert — 두 번 호출해도 에러 없음
        store.clearAll()
        store.clearAll()
        XCTAssertEqual(store.loadAll().count, 0)
    }

    func test_save_sessionWithZeroDuration_persists() {
        // Arrange & Act
        store.save(session: FocusSession(
            durationSeconds: 0, sessionType: .focus, isCompleted: false
        ))

        // Assert
        let loaded = store.loadAll()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.durationSeconds, 0)
    }

    func test_todayStats_mixedSessionTypes_countsOnlyFocus() {
        // Arrange — 모든 세션 타입 혼합
        store.save(session: FocusSession(durationSeconds: 1500, sessionType: .focus, isCompleted: true))
        store.save(session: FocusSession(durationSeconds: 300, sessionType: .shortBreak, isCompleted: true))
        store.save(session: FocusSession(durationSeconds: 900, sessionType: .longBreak, isCompleted: true))
        store.save(session: FocusSession(durationSeconds: 600, sessionType: .focus, isCompleted: false))

        // Act
        let stats = store.todayStats()

        // Assert
        XCTAssertEqual(stats.completedCount, 1) // 완료된 focus만
        XCTAssertEqual(stats.focusSeconds, 2100) // 1500 + 600
    }
}
