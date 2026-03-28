// SettingsViewModelTests.swift
// SettingsViewModel 테스트 — 설정값 저장/로드, 기본값, 프리미엄 상태 검증

import XCTest
@testable import FocusTimer

@MainActor
final class SettingsViewModelTests: XCTestCase {

    private var sut: SettingsViewModel!

    override func setUp() {
        super.setUp()
        // UserDefaults 설정값 초기화
        let keys = [
            "settings.focusMinutes",
            "settings.shortBreakMinutes",
            "settings.longBreakMinutes",
            "settings.longBreakInterval",
            "settings.isPremium",
            "settings.autoStartBreak",
            "settings.soundEnabled"
        ]
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }

        sut = SettingsViewModel()
    }

    override func tearDown() {
        sut = nil
        let keys = [
            "settings.focusMinutes",
            "settings.shortBreakMinutes",
            "settings.longBreakMinutes",
            "settings.longBreakInterval",
            "settings.isPremium",
            "settings.autoStartBreak",
            "settings.soundEnabled"
        ]
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        super.tearDown()
    }

    // MARK: - νₑ 정상 경로 (Happy Path)

    func test_init_defaultValues_allCorrect() {
        XCTAssertEqual(sut.focusMinutes, 25)
        XCTAssertEqual(sut.shortBreakMinutes, 5)
        XCTAssertEqual(sut.longBreakMinutes, 15)
        XCTAssertEqual(sut.longBreakInterval, 4)
        XCTAssertFalse(sut.isPremium)
        XCTAssertFalse(sut.autoStartBreak)
        XCTAssertTrue(sut.soundEnabled)
    }

    func test_setFocusMinutes_persistsToUserDefaults() {
        // Act
        sut.focusMinutes = 30

        // Assert
        XCTAssertEqual(UserDefaults.standard.integer(forKey: "settings.focusMinutes"), 30)
    }

    func test_setShortBreakMinutes_persistsToUserDefaults() {
        // Act
        sut.shortBreakMinutes = 10

        // Assert
        XCTAssertEqual(UserDefaults.standard.integer(forKey: "settings.shortBreakMinutes"), 10)
    }

    func test_setLongBreakMinutes_persistsToUserDefaults() {
        // Act
        sut.longBreakMinutes = 20

        // Assert
        XCTAssertEqual(UserDefaults.standard.integer(forKey: "settings.longBreakMinutes"), 20)
    }

    func test_setLongBreakInterval_persistsToUserDefaults() {
        // Act
        sut.longBreakInterval = 6

        // Assert
        XCTAssertEqual(UserDefaults.standard.integer(forKey: "settings.longBreakInterval"), 6)
    }

    func test_setIsPremium_persistsToUserDefaults() {
        // Act
        sut.isPremium = true

        // Assert
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "settings.isPremium"))
    }

    func test_setSoundEnabled_persistsToUserDefaults() {
        // Act
        sut.soundEnabled = false

        // Assert
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "settings.soundEnabled"))
    }

    func test_resetToDefaults_restoresAllValues() {
        // Arrange — 값 변경
        sut.focusMinutes = 50
        sut.shortBreakMinutes = 15
        sut.longBreakMinutes = 30
        sut.longBreakInterval = 8

        // Act
        sut.resetToDefaults()

        // Assert
        XCTAssertEqual(sut.focusMinutes, 25)
        XCTAssertEqual(sut.shortBreakMinutes, 5)
        XCTAssertEqual(sut.longBreakMinutes, 15)
        XCTAssertEqual(sut.longBreakInterval, 4)
        XCTAssertFalse(sut.autoStartBreak)
        XCTAssertTrue(sut.soundEnabled)
    }

    func test_staticLoaders_returnSavedValues() {
        // Arrange
        sut.focusMinutes = 45
        sut.shortBreakMinutes = 10
        sut.longBreakMinutes = 20
        sut.longBreakInterval = 6
        sut.isPremium = true

        // Act & Assert
        XCTAssertEqual(SettingsViewModel.loadFocusMinutes(), 45)
        XCTAssertEqual(SettingsViewModel.loadShortBreakMinutes(), 10)
        XCTAssertEqual(SettingsViewModel.loadLongBreakMinutes(), 20)
        XCTAssertEqual(SettingsViewModel.loadLongBreakInterval(), 6)
        XCTAssertTrue(SettingsViewModel.loadIsPremium())
    }

    func test_valuesPersistedAcrossInstances() {
        // Arrange
        sut.focusMinutes = 40

        // Act
        let newVM = SettingsViewModel()

        // Assert
        XCTAssertEqual(newVM.focusMinutes, 40)
    }

    // MARK: - νμ 예외 경로 (Error Path)

    func test_staticLoaders_noStoredValue_returnsDefaults() {
        // UserDefaults에 값이 없는 상태 (setUp에서 초기화됨)
        // register(defaults:)를 사용하므로 기본값 반환
        XCTAssertEqual(SettingsViewModel.loadFocusMinutes(), 25)
        XCTAssertEqual(SettingsViewModel.loadShortBreakMinutes(), 5)
        XCTAssertEqual(SettingsViewModel.loadLongBreakMinutes(), 15)
        XCTAssertEqual(SettingsViewModel.loadLongBreakInterval(), 4)
        XCTAssertFalse(SettingsViewModel.loadIsPremium())
    }

    func test_resetToDefaults_doesNotResetPremium() {
        // Arrange
        sut.isPremium = true

        // Act
        sut.resetToDefaults()

        // Assert — resetToDefaults는 isPremium을 초기화하지 않음
        XCTAssertTrue(sut.isPremium)
    }

    // MARK: - ντ 경계 경로 (Edge Case)

    func test_focusMinutes_setToMinimum_persistsOne() {
        // Act
        sut.focusMinutes = 1

        // Assert
        XCTAssertEqual(sut.focusMinutes, 1)
        XCTAssertEqual(SettingsViewModel.loadFocusMinutes(), 1)
    }

    func test_focusMinutes_setToMaximum_persists120() {
        // Act
        sut.focusMinutes = 120

        // Assert
        XCTAssertEqual(sut.focusMinutes, 120)
        XCTAssertEqual(SettingsViewModel.loadFocusMinutes(), 120)
    }

    func test_longBreakInterval_setToMinimum_persistsTwo() {
        // Act
        sut.longBreakInterval = 2

        // Assert
        XCTAssertEqual(sut.longBreakInterval, 2)
    }

    func test_longBreakInterval_setToMaximum_persistsTen() {
        // Act
        sut.longBreakInterval = 10

        // Assert
        XCTAssertEqual(sut.longBreakInterval, 10)
    }

    func test_rapidValueChanges_lastValuePersisted() {
        // Act — 빠르게 여러 번 변경
        for i in 1...50 {
            sut.focusMinutes = i
        }

        // Assert — 마지막 값만 저장
        XCTAssertEqual(sut.focusMinutes, 50)
        XCTAssertEqual(SettingsViewModel.loadFocusMinutes(), 50)
    }

    func test_multipleInstancesCreated_allReadSameDefaults() {
        // Arrange
        sut.focusMinutes = 42

        // Act
        let vm2 = SettingsViewModel()
        let vm3 = SettingsViewModel()

        // Assert
        XCTAssertEqual(vm2.focusMinutes, 42)
        XCTAssertEqual(vm3.focusMinutes, 42)
    }
}
