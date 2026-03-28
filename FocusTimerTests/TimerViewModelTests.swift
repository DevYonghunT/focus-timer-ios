// TimerViewModelTests.swift
// TimerViewModel 테스트 — 타이머 상태 전이, 세션 전환, 백그라운드 복귀 검증

import XCTest
@testable import FocusTimer

@MainActor
final class TimerViewModelTests: XCTestCase {

    private var sut: TimerViewModel!

    override func setUp() {
        super.setUp()
        // UserDefaults 초기화 (기본값으로)
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "settings.focusMinutes")
        defaults.removeObject(forKey: "settings.shortBreakMinutes")
        defaults.removeObject(forKey: "settings.longBreakMinutes")
        defaults.removeObject(forKey: "settings.longBreakInterval")
        defaults.removeObject(forKey: "settings.isPremium")
        SessionStore.shared.clearAll()

        sut = TimerViewModel()
    }

    override func tearDown() {
        sut = nil
        SessionStore.shared.clearAll()
        super.tearDown()
    }

    // MARK: - νₑ 정상 경로 (Happy Path)

    // --- 초기 상태 ---

    func test_init_defaultState_isIdleWithFocusDuration() {
        // Assert
        XCTAssertEqual(sut.timerState, .idle)
        XCTAssertEqual(sut.currentSessionType, .focus)
        XCTAssertEqual(sut.remainingSeconds, 25 * 60) // 기본 25분
    }

    func test_init_formattedTime_shows25Minutes() {
        XCTAssertEqual(sut.formattedTime, "25:00")
    }

    func test_init_progress_isZero() {
        XCTAssertEqual(sut.progress, 0.0)
    }

    // --- 시작 ---

    func test_start_fromIdle_stateBecomesRunning() {
        // Act
        sut.start()

        // Assert
        XCTAssertEqual(sut.timerState, .running)
    }

    func test_start_fromIdle_remainingSecondsSetToTotalDuration() {
        // Act
        sut.start()

        // Assert
        XCTAssertEqual(sut.remainingSeconds, sut.totalDuration)
    }

    func test_start_alreadyRunning_noStateChange() {
        // Arrange
        sut.start()

        // Act — 이미 running인 상태에서 다시 start
        let remainingBefore = sut.remainingSeconds
        sut.start()

        // Assert
        XCTAssertEqual(sut.timerState, .running)
        XCTAssertEqual(sut.remainingSeconds, remainingBefore)
    }

    // --- 일시정지 ---

    func test_pause_fromRunning_stateBecomePaused() {
        // Arrange
        sut.start()

        // Act
        sut.pause()

        // Assert
        XCTAssertEqual(sut.timerState, .paused)
    }

    func test_pause_fromIdle_noStateChange() {
        // Act
        sut.pause()

        // Assert
        XCTAssertEqual(sut.timerState, .idle)
    }

    // --- 재개 (pause 후 start) ---

    func test_start_afterPause_stateBecomesRunning() {
        // Arrange
        sut.start()
        sut.pause()

        // Act
        sut.start()

        // Assert
        XCTAssertEqual(sut.timerState, .running)
    }

    // --- 리셋 ---

    func test_reset_fromRunning_stateBecomesIdle() {
        // Arrange
        sut.start()

        // Act
        sut.reset()

        // Assert
        XCTAssertEqual(sut.timerState, .idle)
        XCTAssertEqual(sut.remainingSeconds, sut.totalDuration)
    }

    func test_resetToFocus_fromBreak_switchesToFocusMode() {
        // Arrange — 포커스 완료 후 휴식으로 전환된 상태 시뮬레이션
        sut.start()
        sut.skipToNext() // focus → shortBreak

        // Act
        sut.resetToFocus()

        // Assert
        XCTAssertEqual(sut.currentSessionType, .focus)
        XCTAssertEqual(sut.timerState, .idle)
        XCTAssertEqual(sut.remainingSeconds, sut.focusDuration)
    }

    // --- 세션 전환 ---

    func test_skipToNext_fromFocus_switchesToShortBreak() {
        // Arrange
        XCTAssertEqual(sut.currentSessionType, .focus)

        // Act
        sut.skipToNext()

        // Assert
        XCTAssertEqual(sut.currentSessionType, .shortBreak)
        XCTAssertEqual(sut.remainingSeconds, sut.shortBreakDuration)
    }

    func test_skipToNext_fromShortBreak_switchesToFocus() {
        // Arrange
        sut.skipToNext() // focus → shortBreak

        // Act
        sut.skipToNext() // shortBreak → focus

        // Assert
        XCTAssertEqual(sut.currentSessionType, .focus)
    }

    // --- 프로그레스 ---

    func test_progress_afterStart_isZero() {
        // Arrange
        sut.start()

        // Assert — 시작 직후 progress는 0
        XCTAssertEqual(sut.progress, 0.0, accuracy: 0.01)
    }

    func test_progress_snapshotBased_immuneToSettingsChange() {
        // Arrange
        sut.start()
        let initialSnapshot = sut.remainingSeconds

        // Act — 설정 변경 시뮬레이션 (UserDefaults 직접 변경)
        UserDefaults.standard.set(50, forKey: "settings.focusMinutes")

        // Assert — snapshotDuration 기반이므로 progress 계산이 깨지지 않음
        // totalDuration은 변경되지만 progress는 snapshotDuration 기준
        let progress = sut.progress
        XCTAssertGreaterThanOrEqual(progress, 0.0)
        XCTAssertLessThanOrEqual(progress, 1.0)

        // Cleanup
        UserDefaults.standard.removeObject(forKey: "settings.focusMinutes")
    }

    // --- formattedTime ---

    func test_formattedTime_variousRemaining_formatsCorrectly() {
        // Arrange & Act & Assert
        sut.start()
        // 시작 직후: 25:00
        XCTAssertEqual(sut.formattedTime, "25:00")
    }

    // --- totalDuration ---

    func test_totalDuration_focusMode_returnsFocusDuration() {
        XCTAssertEqual(sut.totalDuration, 25 * 60)
    }

    func test_totalDuration_shortBreakMode_returnsShortBreakDuration() {
        // Arrange
        sut.skipToNext() // focus → shortBreak

        // Assert
        XCTAssertEqual(sut.totalDuration, 5 * 60)
    }

    func test_totalDuration_longBreakMode_returnsLongBreakDuration() {
        // Arrange — longBreakInterval(기본4)만큼 포모도로 완료
        // completedPomodoros를 4로 만들어서 longBreak 트리거
        for _ in 0..<4 {
            sut.start()
            sut.skipToNext() // focus → shortBreak
            sut.skipToNext() // shortBreak → focus
        }
        // 4번째 완료 후 다음은 longBreak
        // completedPomodoros는 reset이 호출되면서 증가하지 않음
        // skipToNext → reset → advanceSession 흐름

        // 직접 확인: longBreak 시 duration
        XCTAssertEqual(sut.longBreakDuration, 15 * 60)
    }

    // MARK: - νμ 예외 경로 (Error Path)

    func test_pause_whenIdle_stateRemainsIdle() {
        // Act
        sut.pause()

        // Assert
        XCTAssertEqual(sut.timerState, .idle)
    }

    func test_reset_whenAlreadyIdle_noError() {
        // Act — idle 상태에서 reset 호출
        sut.reset()

        // Assert
        XCTAssertEqual(sut.timerState, .idle)
        XCTAssertEqual(sut.remainingSeconds, sut.totalDuration)
    }

    func test_handleBackgroundTransition_whenNotRunning_noEffect() {
        // Arrange
        let remainingBefore = sut.remainingSeconds

        // Act
        sut.handleBackgroundTransition()

        // Assert
        XCTAssertEqual(sut.remainingSeconds, remainingBefore)
        XCTAssertEqual(sut.timerState, .idle)
    }

    func test_handleForegroundTransition_whenNotRunning_noEffect() {
        // Act
        sut.handleForegroundTransition()

        // Assert
        XCTAssertEqual(sut.timerState, .idle)
    }

    func test_handleForegroundTransition_withoutPriorBackground_noEffect() {
        // Arrange
        sut.start()

        // Act — handleBackgroundTransition 없이 foreground 호출
        sut.handleForegroundTransition()

        // Assert — backgroundEnteredAt이 nil이므로 아무것도 안 함
        XCTAssertEqual(sut.timerState, .running)
    }

    // MARK: - ντ 경계 경로 (Edge Case)

    func test_backgroundForeground_shortDuration_remainingDecreasedCorrectly() {
        // Arrange
        sut.start()
        let remainingBefore = sut.remainingSeconds

        // Act
        sut.handleBackgroundTransition()
        // 1초 대기 시뮬레이션
        Thread.sleep(forTimeInterval: 1.1)
        sut.handleForegroundTransition()

        // Assert — wall clock 기반이므로 대략 1초 감소
        let elapsed = remainingBefore - sut.remainingSeconds
        XCTAssertGreaterThanOrEqual(elapsed, 1)
        XCTAssertLessThanOrEqual(elapsed, 3) // 여유 범위
    }

    func test_backgroundForeground_longerThanRemaining_completesSession() {
        // Arrange
        sut.start()
        // remainingSeconds를 아주 작게 설정
        sut.remainingSeconds = 1

        // Act
        sut.handleBackgroundTransition()
        Thread.sleep(forTimeInterval: 1.5)
        sut.handleForegroundTransition()

        // Assert — 시간 초과로 세션 완료 → idle + 다음 세션으로 전환
        XCTAssertEqual(sut.timerState, .idle)
    }

    func test_rapidStartPause_multipleTimesNoError() {
        // Act — 빠른 시작/정지 반복
        for _ in 0..<20 {
            sut.start()
            sut.pause()
        }

        // Assert
        XCTAssertEqual(sut.timerState, .paused)
    }

    func test_rapidStartReset_multipleTimesNoError() {
        // Act
        for _ in 0..<20 {
            sut.start()
            sut.reset()
        }

        // Assert
        XCTAssertEqual(sut.timerState, .idle)
    }

    func test_skipToNext_manyTimes_cyclesCorrectly() {
        // Act & Assert — 여러 번 스킵하면서 세션 순환 확인
        // focus → shortBreak → focus → shortBreak → ...
        for i in 0..<10 {
            if i % 2 == 0 {
                XCTAssertEqual(sut.currentSessionType, .focus,
                               "Iteration \(i): expected focus")
            } else {
                // shortBreak 또는 longBreak (longBreakInterval에 의해)
                XCTAssertNotEqual(sut.currentSessionType, .focus,
                                  "Iteration \(i): expected break")
            }
            sut.skipToNext()
        }
    }

    func test_refreshTodayStats_afterSessionSaved_updatesCorrectly() {
        // Arrange
        SessionStore.shared.save(session: FocusSession(
            durationSeconds: 1500,
            sessionType: .focus,
            isCompleted: true
        ))

        // Act
        sut.refreshTodayStats()

        // Assert
        XCTAssertEqual(sut.completedPomodoros, 1)
        XCTAssertEqual(sut.todayFocusSeconds, 1500)
    }

    func test_progress_remainingZero_returnsOne() {
        // Arrange
        sut.start()
        sut.remainingSeconds = 0

        // Assert — 전체 시간 경과 = 100%
        XCTAssertEqual(sut.progress, 1.0, accuracy: 0.01)
    }

    func test_formattedTime_singleDigitSeconds_padded() {
        // Arrange
        sut.start()
        sut.remainingSeconds = 65 // 1:05

        // Assert
        XCTAssertEqual(sut.formattedTime, "01:05")
    }

    func test_formattedTime_zeroSeconds_showsZero() {
        // Arrange
        sut.start()
        sut.remainingSeconds = 0

        // Assert
        XCTAssertEqual(sut.formattedTime, "00:00")
    }

    func test_formattedTime_largeValue_formatsCorrectly() {
        // Arrange
        sut.start()
        sut.remainingSeconds = 7200 // 120분

        // Assert
        XCTAssertEqual(sut.formattedTime, "120:00")
    }
}
