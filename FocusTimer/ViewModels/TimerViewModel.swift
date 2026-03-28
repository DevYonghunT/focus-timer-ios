// TimerViewModel.swift
// 타이머 핵심 로직 — 포모도로 타이머 상태 관리

import Foundation
import Combine
import SwiftUI
import UserNotifications
import os

/// 포모도로 타이머 뷰모델
@MainActor
final class TimerViewModel: ObservableObject {
    // MARK: - 발행 속성

    /// 남은 시간 (초)
    @Published var remainingSeconds: Int = 0
    /// 현재 타이머 상태
    @Published var timerState: TimerState = .idle
    /// 현재 세션 유형
    @Published var currentSessionType: SessionType = .focus
    /// 오늘 완료한 포모도로 수
    @Published var completedPomodoros: Int = 0
    /// 오늘 총 집중 시간 (초)
    @Published var todayFocusSeconds: Int = 0

    // MARK: - 내부 상태

    private var timer: AnyCancellable?
    private var sessionStartedAt: Date?
    private var elapsedBeforePause: Int = 0
    private let store = SessionStore.shared

    /// 세션 시작 시 고정된 전체 시간 스냅샷 (설정 변경에 의한 progress 깨짐 방지)
    private var snapshotDuration: Int = 0

    /// 백그라운드 전환 시점 기록 (wall clock 기반 시간 계산용)
    private var backgroundEnteredAt: Date?

    /// 설정에서 가져오는 시간 값 (초)
    var focusDuration: Int {
        SettingsViewModel.loadFocusMinutes() * 60
    }
    var shortBreakDuration: Int {
        SettingsViewModel.loadShortBreakMinutes() * 60
    }
    var longBreakDuration: Int {
        SettingsViewModel.loadLongBreakMinutes() * 60
    }
    /// 긴 휴식까지 필요한 포모도로 수
    var longBreakInterval: Int {
        SettingsViewModel.loadLongBreakInterval()
    }

    /// 전체 세션 길이 (현재 세션 유형 기준)
    var totalDuration: Int {
        switch currentSessionType {
        case .focus:
            return focusDuration
        case .shortBreak:
            return shortBreakDuration
        case .longBreak:
            return longBreakDuration
        }
    }

    /// 프로그레스 비율 (0.0 ~ 1.0) — 스냅샷 기반으로 계산하여 설정 변경에 안전
    var progress: Double {
        guard snapshotDuration > 0 else { return 0 }
        return 1.0 - (Double(remainingSeconds) / Double(snapshotDuration))
    }

    /// 남은 시간 포맷 (mm:ss)
    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - 초기화

    init() {
        resetToFocus()
        refreshTodayStats()
    }

    // MARK: - 공개 메서드

    /// 타이머 시작
    func start() {
        guard timerState != .running else { return }

        if timerState == .idle {
            sessionStartedAt = Date()
            elapsedBeforePause = 0
            remainingSeconds = totalDuration
            // 세션 시작 시 전체 시간을 스냅샷으로 고정
            snapshotDuration = totalDuration
        }

        timerState = .running
        // 백그라운드 알림 예약 (남은 시간 후 발동)
        scheduleBackgroundNotification()
        startTicking()
    }

    /// 타이머 일시정지
    func pause() {
        guard timerState == .running else { return }
        timerState = .paused
        elapsedBeforePause = snapshotDuration - remainingSeconds
        stopTicking()
        // 일시정지 시 예약된 백그라운드 알림 취소
        cancelBackgroundNotification()
    }

    /// 타이머 초기화 (현재 세션 유형 유지)
    func reset() {
        // 진행 중이던 세션이 있으면 미완료로 기록
        if timerState != .idle, let startedAt = sessionStartedAt {
            let elapsed = snapshotDuration - remainingSeconds
            if elapsed > 0 {
                recordSession(startedAt: startedAt, duration: elapsed, completed: false)
            }
        }

        stopTicking()
        cancelBackgroundNotification()
        timerState = .idle
        remainingSeconds = totalDuration
        snapshotDuration = totalDuration
        sessionStartedAt = nil
        elapsedBeforePause = 0
    }

    /// 집중 모드로 리셋
    func resetToFocus() {
        stopTicking()
        cancelBackgroundNotification()
        timerState = .idle
        currentSessionType = .focus
        remainingSeconds = focusDuration
        snapshotDuration = focusDuration
        sessionStartedAt = nil
        elapsedBeforePause = 0
    }

    /// 다음 세션으로 자동 전환
    func skipToNext() {
        reset()
        advanceSession()
    }

    /// 앱이 백그라운드로 전환될 때 호출 (scenePhase 감지)
    func handleBackgroundTransition() {
        guard timerState == .running else { return }
        backgroundEnteredAt = Date()
        stopTicking()
    }

    /// 앱이 포그라운드로 복귀할 때 호출 (scenePhase 감지)
    func handleForegroundTransition() {
        guard timerState == .running, let enteredAt = backgroundEnteredAt else { return }

        // wall clock 기반으로 경과 시간 계산
        let elapsedInBackground = Int(Date().timeIntervalSince(enteredAt))
        remainingSeconds = max(0, remainingSeconds - elapsedInBackground)
        backgroundEnteredAt = nil

        if remainingSeconds <= 0 {
            remainingSeconds = 0
            handleSessionComplete()
        } else {
            startTicking()
        }
    }

    // MARK: - Private

    /// 1초 간격 타이머 시작
    private func startTicking() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    /// 타이머 정지
    private func stopTicking() {
        timer?.cancel()
        timer = nil
    }

    /// 매 초 호출
    private func tick() {
        // 이미 완료 처리 중이거나 running이 아니면 무시 (이중 호출 방지)
        guard timerState == .running else { return }
        guard remainingSeconds > 0 else { return }

        remainingSeconds -= 1

        if remainingSeconds <= 0 {
            handleSessionComplete()
        }
    }

    /// 세션 완료 처리
    private func handleSessionComplete() {
        // 이미 idle 상태면 중복 실행 방지
        guard timerState != .idle else { return }

        stopTicking()
        cancelBackgroundNotification()

        if let startedAt = sessionStartedAt {
            recordSession(startedAt: startedAt, duration: snapshotDuration, completed: true)
        }

        scheduleCompletionNotification()
        timerState = .idle
        sessionStartedAt = nil
        elapsedBeforePause = 0

        // 포모도로 카운터 업데이트
        if currentSessionType == .focus {
            completedPomodoros += 1
        }

        refreshTodayStats()
        advanceSession()
    }

    /// 다음 세션 유형으로 전환
    private func advanceSession() {
        switch currentSessionType {
        case .focus:
            // 긴 휴식 인터벌 도달 시 긴 휴식
            if completedPomodoros > 0 && completedPomodoros % longBreakInterval == 0 {
                currentSessionType = .longBreak
                remainingSeconds = longBreakDuration
                snapshotDuration = longBreakDuration
            } else {
                currentSessionType = .shortBreak
                remainingSeconds = shortBreakDuration
                snapshotDuration = shortBreakDuration
            }
        case .shortBreak, .longBreak:
            currentSessionType = .focus
            remainingSeconds = focusDuration
            snapshotDuration = focusDuration
        }
    }

    /// 세션 기록 저장
    private func recordSession(startedAt: Date, duration: Int, completed: Bool) {
        let session = FocusSession(
            startedAt: startedAt,
            durationSeconds: duration,
            sessionType: currentSessionType,
            isCompleted: completed
        )
        store.save(session: session)
    }

    /// 오늘 통계 새로고침 (한 번의 로드로 통합 조회)
    func refreshTodayStats() {
        let stats = store.todayStats()
        completedPomodoros = stats.completedCount
        todayFocusSeconds = stats.focusSeconds
    }

    /// 현재 세션 유형에 맞는 알림 메시지 생성
    private func sessionMessage() -> (title: String, body: String) {
        switch currentSessionType {
        case .focus:
            return ("집중 세션 완료!", "잘했어요! 잠시 쉬어가세요.")
        case .shortBreak:
            return ("짧은 휴식 끝!", "다시 집중할 시간이에요.")
        case .longBreak:
            return ("긴 휴식 끝!", "새로운 집중 세션을 시작하세요.")
        }
    }

    /// 타이머 완료 시 로컬 알림 발송 (즉시)
    private func scheduleCompletionNotification() {
        let message = sessionMessage()
        let content = UNMutableNotificationContent()
        content.title = message.title
        content.body = message.body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                AppLogger.notification.error("알림 발송 실패: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - 백그라운드 알림 예약/취소

    /// 백그라운드 타이머 알림 식별자
    private let backgroundNotificationID = "com.focustimer.background-timer"

    /// 남은 시간 후 발동되는 백그라운드 알림 예약
    private func scheduleBackgroundNotification() {
        cancelBackgroundNotification()

        let message = sessionMessage()
        let content = UNMutableNotificationContent()
        content.title = message.title
        content.body = message.body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(max(1, remainingSeconds)),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: backgroundNotificationID,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                AppLogger.notification.error("백그라운드 알림 예약 실패: \(error.localizedDescription)")
            }
        }
    }

    /// 예약된 백그라운드 알림 취소
    private func cancelBackgroundNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [backgroundNotificationID]
        )
    }
}
