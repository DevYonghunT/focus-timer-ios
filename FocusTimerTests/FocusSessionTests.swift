// FocusSessionTests.swift
// FocusSession 모델 테스트 — 데이터 모델 생성, Codable, 열거형 검증

import XCTest
@testable import FocusTimer

final class FocusSessionTests: XCTestCase {

    // MARK: - νₑ 정상 경로 (Happy Path)

    func test_init_defaultValues_createsSessionWithUUIDAndCurrentDate() {
        // Arrange & Act
        let session = FocusSession(
            durationSeconds: 1500,
            sessionType: .focus,
            isCompleted: true
        )

        // Assert
        XCTAssertNotNil(session.id)
        XCTAssertEqual(session.durationSeconds, 1500)
        XCTAssertEqual(session.sessionType, .focus)
        XCTAssertTrue(session.isCompleted)
    }

    func test_init_customValues_preservesAllFields() {
        // Arrange
        let customDate = Date(timeIntervalSince1970: 1000000)
        let customID = UUID()

        // Act
        let session = FocusSession(
            id: customID,
            startedAt: customDate,
            durationSeconds: 300,
            sessionType: .shortBreak,
            isCompleted: false
        )

        // Assert
        XCTAssertEqual(session.id, customID)
        XCTAssertEqual(session.startedAt, customDate)
        XCTAssertEqual(session.durationSeconds, 300)
        XCTAssertEqual(session.sessionType, .shortBreak)
        XCTAssertFalse(session.isCompleted)
    }

    func test_codable_encodeDecode_preservesData() throws {
        // Arrange
        let original = FocusSession(
            startedAt: Date(timeIntervalSince1970: 1711000000),
            durationSeconds: 1500,
            sessionType: .focus,
            isCompleted: true
        )
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        // Act
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(FocusSession.self, from: data)

        // Assert
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.startedAt, original.startedAt)
        XCTAssertEqual(decoded.durationSeconds, original.durationSeconds)
        XCTAssertEqual(decoded.sessionType, original.sessionType)
        XCTAssertEqual(decoded.isCompleted, original.isCompleted)
    }

    func test_sessionType_focus_rawValue_isFocus() {
        XCTAssertEqual(SessionType.focus.rawValue, "focus")
    }

    func test_sessionType_shortBreak_rawValue_isShortBreak() {
        XCTAssertEqual(SessionType.shortBreak.rawValue, "shortBreak")
    }

    func test_sessionType_longBreak_rawValue_isLongBreak() {
        XCTAssertEqual(SessionType.longBreak.rawValue, "longBreak")
    }

    // MARK: - νμ 예외 경로 (Error Path)

    func test_codable_invalidJSON_throwsDecodingError() {
        // Arrange
        let invalidJSON = Data("{}".utf8)
        let decoder = JSONDecoder()

        // Act & Assert
        XCTAssertThrowsError(try decoder.decode(FocusSession.self, from: invalidJSON))
    }

    func test_sessionType_invalidRawValue_returnsNil() {
        // Act
        let invalid = SessionType(rawValue: "invalidType")

        // Assert
        XCTAssertNil(invalid)
    }

    // MARK: - ντ 경계 경로 (Edge Case)

    func test_init_zeroDuration_createsSession() {
        // Arrange & Act
        let session = FocusSession(
            durationSeconds: 0,
            sessionType: .focus,
            isCompleted: false
        )

        // Assert
        XCTAssertEqual(session.durationSeconds, 0)
    }

    func test_init_veryLargeDuration_createsSession() {
        // Arrange & Act
        let session = FocusSession(
            durationSeconds: Int.max,
            sessionType: .focus,
            isCompleted: true
        )

        // Assert
        XCTAssertEqual(session.durationSeconds, Int.max)
    }

    func test_codable_arrayEncodeDecode_preservesOrder() throws {
        // Arrange
        let sessions = (0..<100).map { i in
            FocusSession(
                durationSeconds: i * 60,
                sessionType: [.focus, .shortBreak, .longBreak][i % 3],
                isCompleted: i % 2 == 0
            )
        }
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        // Act
        let data = try encoder.encode(sessions)
        let decoded = try decoder.decode([FocusSession].self, from: data)

        // Assert
        XCTAssertEqual(decoded.count, 100)
        for i in 0..<100 {
            XCTAssertEqual(decoded[i].id, sessions[i].id)
            XCTAssertEqual(decoded[i].durationSeconds, sessions[i].durationSeconds)
        }
    }

    func test_identifiable_uniqueIDs_allSessionsHaveDistinctIDs() {
        // Arrange & Act
        let sessions = (0..<50).map { _ in
            FocusSession(durationSeconds: 100, sessionType: .focus, isCompleted: true)
        }
        let ids = Set(sessions.map { $0.id })

        // Assert
        XCTAssertEqual(ids.count, 50)
    }
}
