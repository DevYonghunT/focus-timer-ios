// FocusSession.swift
// 포모도로 세션 데이터 모델 — UserDefaults 기반 저장

import Foundation

/// 개별 집중 세션 기록
struct FocusSession: Codable, Identifiable {
    let id: UUID
    /// 세션 시작 시각
    let startedAt: Date
    /// 실제 집중한 시간 (초)
    let durationSeconds: Int
    /// 세션 유형 (집중 / 휴식)
    let sessionType: SessionType
    /// 완료 여부 (중간 포기 vs 완주)
    let isCompleted: Bool

    init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        durationSeconds: Int,
        sessionType: SessionType,
        isCompleted: Bool
    ) {
        self.id = id
        self.startedAt = startedAt
        self.durationSeconds = durationSeconds
        self.sessionType = sessionType
        self.isCompleted = isCompleted
    }
}

/// 세션 유형
enum SessionType: String, Codable {
    case focus = "focus"
    case shortBreak = "shortBreak"
    case longBreak = "longBreak"
}

/// 타이머 실행 상태
enum TimerState {
    case idle
    case running
    case paused
}

/// 통계 기간 필터
enum StatsPeriod: String, CaseIterable {
    case daily = "일간"
    case weekly = "주간"
    case monthly = "월간"
}
