// SettingsViewModel.swift
// 설정 뷰모델 — 타이머 설정값 관리 (모든 기능 무료 해금)

import Foundation

/// 설정 뷰모델
@MainActor
final class SettingsViewModel: ObservableObject {
    // MARK: - UserDefaults 키

    private enum Keys {
        static let focusMinutes = "settings.focusMinutes"
        static let shortBreakMinutes = "settings.shortBreakMinutes"
        static let longBreakMinutes = "settings.longBreakMinutes"
        static let longBreakInterval = "settings.longBreakInterval"
        static let autoStartBreak = "settings.autoStartBreak"
        static let soundEnabled = "settings.soundEnabled"
    }

    // MARK: - 기본값

    private enum Defaults {
        static let focusMinutes = 25
        static let shortBreakMinutes = 5
        static let longBreakMinutes = 15
        static let longBreakInterval = 4
    }

    // MARK: - 발행 속성

    @Published var focusMinutes: Int {
        didSet { UserDefaults.standard.set(focusMinutes, forKey: Keys.focusMinutes) }
    }

    @Published var shortBreakMinutes: Int {
        didSet { UserDefaults.standard.set(shortBreakMinutes, forKey: Keys.shortBreakMinutes) }
    }

    @Published var longBreakMinutes: Int {
        didSet { UserDefaults.standard.set(longBreakMinutes, forKey: Keys.longBreakMinutes) }
    }

    @Published var longBreakInterval: Int {
        didSet { UserDefaults.standard.set(longBreakInterval, forKey: Keys.longBreakInterval) }
    }

    /// 모든 기능 무료 해금 — 항상 true
    let isPremium: Bool = true

    @Published var autoStartBreak: Bool {
        didSet { UserDefaults.standard.set(autoStartBreak, forKey: Keys.autoStartBreak) }
    }

    @Published var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: Keys.soundEnabled) }
    }

    // MARK: - 초기화

    init() {
        let defaults = UserDefaults.standard

        // 최초 실행 시 기본값 등록
        defaults.register(defaults: [
            Keys.focusMinutes: Defaults.focusMinutes,
            Keys.shortBreakMinutes: Defaults.shortBreakMinutes,
            Keys.longBreakMinutes: Defaults.longBreakMinutes,
            Keys.longBreakInterval: Defaults.longBreakInterval,
            Keys.autoStartBreak: false,
            Keys.soundEnabled: true,
        ])

        self.focusMinutes = defaults.integer(forKey: Keys.focusMinutes)
        self.shortBreakMinutes = defaults.integer(forKey: Keys.shortBreakMinutes)
        self.longBreakMinutes = defaults.integer(forKey: Keys.longBreakMinutes)
        self.longBreakInterval = defaults.integer(forKey: Keys.longBreakInterval)
        self.autoStartBreak = defaults.bool(forKey: Keys.autoStartBreak)
        self.soundEnabled = defaults.bool(forKey: Keys.soundEnabled)
    }

    /// 기본값으로 초기화
    func resetToDefaults() {
        focusMinutes = Defaults.focusMinutes
        shortBreakMinutes = Defaults.shortBreakMinutes
        longBreakMinutes = Defaults.longBreakMinutes
        longBreakInterval = Defaults.longBreakInterval
        autoStartBreak = false
        soundEnabled = true
    }

    // MARK: - 정적 접근자 (TimerViewModel용)

    static func loadFocusMinutes() -> Int {
        let value = UserDefaults.standard.integer(forKey: Keys.focusMinutes)
        return value > 0 ? value : Defaults.focusMinutes
    }

    static func loadShortBreakMinutes() -> Int {
        let value = UserDefaults.standard.integer(forKey: Keys.shortBreakMinutes)
        return value > 0 ? value : Defaults.shortBreakMinutes
    }

    static func loadLongBreakMinutes() -> Int {
        let value = UserDefaults.standard.integer(forKey: Keys.longBreakMinutes)
        return value > 0 ? value : Defaults.longBreakMinutes
    }

    static func loadLongBreakInterval() -> Int {
        let value = UserDefaults.standard.integer(forKey: Keys.longBreakInterval)
        return value > 0 ? value : Defaults.longBreakInterval
    }

    static func loadIsPremium() -> Bool {
        return true
    }
}
