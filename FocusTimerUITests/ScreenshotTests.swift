// ScreenshotTests.swift
// 앱스토어 스크린샷 자동 캡처

import XCTest

final class ScreenshotTests: XCTestCase {

    let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = false
        app.launch()
    }

    /// 주요 화면 스크린샷 자동 캡처
    func test_captureAllScreenshots() {
        // 앱 로드 대기
        sleep(2)

        // 1. 타이머 메인 화면
        captureScreenshot(name: "01_timer_main")

        // 2. 통계 탭
        let statisticsTab = app.tabBars.buttons["통계"]
        if statisticsTab.exists {
            statisticsTab.tap()
            sleep(1)
            captureScreenshot(name: "02_statistics")
        }

        // 3. 설정 탭
        let settingsTab = app.tabBars.buttons["설정"]
        if settingsTab.exists {
            settingsTab.tap()
            sleep(1)
            captureScreenshot(name: "03_settings")
        }

        // 4. 타이머 탭으로 돌아가기
        let timerTab = app.tabBars.buttons["타이머"]
        if timerTab.exists {
            timerTab.tap()
            sleep(1)
        }

        // 5. 시작 버튼 탭 (타이머 실행 화면)
        let startButton = app.buttons["시작"]
        if startButton.exists {
            startButton.tap()
            sleep(1)
            captureScreenshot(name: "04_timer_running")
        }
    }

    /// 스크린샷 캡처 헬퍼
    private func captureScreenshot(name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
