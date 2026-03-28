// SessionStore.swift
// 세션 기록 저장소 — UserDefaults 기반 영속화

import Foundation
import os

/// 세션 기록을 UserDefaults에 저장/조회하는 저장소
final class SessionStore {
    static let shared = SessionStore()

    private let storageKey = "com.focustimer.sessions"
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {}

    /// 모든 세션 기록 로드
    func loadAll() -> [FocusSession] {
        guard let data = defaults.data(forKey: storageKey) else {
            return []
        }
        do {
            return try decoder.decode([FocusSession].self, from: data)
        } catch {
            AppLogger.store.error("세션 기록 디코딩 실패: \(error.localizedDescription)")
            return []
        }
    }

    /// 새 세션 저장
    func save(session: FocusSession) {
        var sessions = loadAll()
        sessions.append(session)
        persist(sessions)
    }

    /// 전체 기록 초기화
    func clearAll() {
        defaults.removeObject(forKey: storageKey)
    }

    /// 특정 날짜의 세션만 필터링
    func sessions(for date: Date) -> [FocusSession] {
        let calendar = Calendar.current
        return loadAll().filter { session in
            calendar.isDate(session.startedAt, inSameDayAs: date)
        }
    }

    /// 특정 기간의 세션 필터링 (startOfDay 보정 적용)
    func sessions(from startDate: Date, to endDate: Date) -> [FocusSession] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        // endDate의 다음 날 시작 시점까지 포함 (해당 일자 세션 누락 방지)
        let endOfDay = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: endDate) ?? endDate)
        return loadAll().filter { session in
            session.startedAt >= start && session.startedAt < endOfDay
        }
    }

    /// 오늘 완료한 포모도로 수
    func todayCompletedCount() -> Int {
        return sessions(for: Date()).filter {
            $0.sessionType == .focus && $0.isCompleted
        }.count
    }

    /// 오늘 총 집중 시간 (초)
    func todayFocusSeconds() -> Int {
        return sessions(for: Date())
            .filter { $0.sessionType == .focus }
            .reduce(0) { $0 + $1.durationSeconds }
    }

    /// 오늘 통계를 한 번의 loadAll()로 가져오는 통합 메서드 (이중 로드 방지)
    func todayStats() -> (completedCount: Int, focusSeconds: Int) {
        let todaySessions = sessions(for: Date())
        let focusSessions = todaySessions.filter { $0.sessionType == .focus }
        let completedCount = focusSessions.filter { $0.isCompleted }.count
        let focusSeconds = focusSessions.reduce(0) { $0 + $1.durationSeconds }
        return (completedCount, focusSeconds)
    }

    // MARK: - Private

    private func persist(_ sessions: [FocusSession]) {
        do {
            let data = try encoder.encode(sessions)
            defaults.set(data, forKey: storageKey)
        } catch {
            AppLogger.store.error("세션 기록 인코딩 실패: \(error.localizedDescription)")
        }
    }
}
