//
//  GenerateVerseInteractorTests.swift
//  DomainTests
//
//  Created by 이승주 on 10/8/25.
//

import XCTest
@testable import Domain

final class GenerateVerseUseCaseTests: XCTestCase {
    var useCase: GenerateVerseInteractor!
    var spyAIRepository: SpyAIRepository!
    var spyRateLimiterRepository: SpyRateLimiterRepository!

    override func setUp() {
        super.setUp()
        spyAIRepository = SpyAIRepository()
        spyRateLimiterRepository = SpyRateLimiterRepository()
        useCase = GenerateVerseInteractor(
            aiRepository: spyAIRepository,
            rateLimiterRepository: spyRateLimiterRepository
        )
    }

    override func tearDown() {
        useCase = nil
        spyAIRepository = nil
        spyRateLimiterRepository = nil
        super.tearDown()
    }

    // MARK: - Test Case 1: 입력 검증 실패 (너무 짧음)

    func testInputTooShort_ThrowsValidationError() async throws {
        // Given: 너무 짧은 입력
        spyRateLimiterRepository.shouldAllow = true

        // When/Then
        do {
            _ = try await useCase.execute(normalizedText: "a", userId: "user123", timeZone: .current)
            XCTFail("Expected validationFailed error")
        } catch {
            guard case DomainError.validationFailed(let message) = error else {
                XCTFail("Expected validationFailed, got \(error)")
                return
            }
            XCTAssertTrue(message.contains("짧습니다"))
        }

        // Then: 행동 검증 - Rate limiter가 호출되지 않았는지 확인
        XCTAssertEqual(spyRateLimiterRepository.checkDailyCallCount, 0)
        XCTAssertEqual(spyAIRepository.generateVerseCallCount, 0)
    }

    // MARK: - Test Case 2: Daily Limit 초과 → DomainError.rateLimited

    func testDailyLimitExceeded_ThrowsRateLimited() async throws {
        // Given: 하루 1회 제한 초과 상태
        spyRateLimiterRepository.shouldAllow = false

        // When/Then
        do {
            _ = try await useCase.execute(normalizedText: "오늘 힘든 하루였어요", userId: "user123", timeZone: .current)
            XCTFail("Expected rateLimited error")
        } catch {
            guard case DomainError.rateLimited = error else {
                XCTFail("Expected rateLimited, got \(error)")
                return
            }
            // Success
        }

        // Then: 행동 검증 - Daily limiter가 정확히 1번 호출되었는지 확인
        XCTAssertEqual(spyRateLimiterRepository.checkDailyCallCount, 1)
        XCTAssertEqual(spyRateLimiterRepository.lastDailyKey, "generate_verse:user123")
        XCTAssertNotNil(spyRateLimiterRepository.lastTimeZone)

        // Then: 행동 검증 - AIRepository는 호출되지 않았는지 확인
        XCTAssertEqual(spyAIRepository.generateVerseCallCount, 0)
    }

    // MARK: - Test Case 3: Content Blocked → DomainError.moderationBlocked

    func testContentBlocked_ThrowsModerationBlocked() async throws {
        // Given: Rate Limit 통과, AI가 blocked 반환
        spyRateLimiterRepository.shouldAllow = true
        spyAIRepository.shouldBlockContent = true
        spyAIRepository.blockReason = "inappropriate_content"

        // When/Then
        do {
            _ = try await useCase.execute(normalizedText: "부적절한 내용", userId: "user123", timeZone: .current)
            XCTFail("Expected moderationBlocked error")
        } catch {
            guard case DomainError.moderationBlocked(let reason) = error else {
                XCTFail("Expected moderationBlocked, got \(error)")
                return
            }
            XCTAssertEqual(reason, "inappropriate_content")
        }

        // Verify: Daily limiter와 AI Repository가 호출되었는지 확인
        XCTAssertEqual(spyRateLimiterRepository.checkDailyCallCount, 1)
        XCTAssertEqual(spyAIRepository.generateVerseCallCount, 1)
    }

    // MARK: - Test Case 4: 정상 생성

    func testSuccessfulGeneration() async throws {
        // Given: 모든 검증 통과
        spyRateLimiterRepository.shouldAllow = true
        spyAIRepository.generatedVerse = GeneratedVerse(
            verse: Verse(
                book: "시편",
                chapter: 23,
                verse: 1,
                text: "여호와는 나의 목자시니 내게 부족함이 없으리로다",
                translation: "개역개정"
            ),
            reason: "오늘 힘든 하루를 보내신 당신에게 위로가 되길 바랍니다"
        )

        // When
        let result = try await useCase.execute(normalizedText: "오늘 힘든 하루였어요", userId: "user123", timeZone: .current)

        // Then
        XCTAssertEqual(result.verse.book, "시편")
        XCTAssertEqual(result.verse.chapter, 23)
        XCTAssertEqual(result.verse.verse, 1)
        XCTAssertEqual(result.verse.text, "여호와는 나의 목자시니 내게 부족함이 없으리로다")
        XCTAssertTrue(result.reason.contains("위로"))

        // Verify: 모든 단계가 순서대로 호출되었는지 확인
        XCTAssertEqual(spyRateLimiterRepository.checkDailyCallCount, 1)
        XCTAssertEqual(spyAIRepository.generateVerseCallCount, 1)
        XCTAssertEqual(spyAIRepository.lastRequest?.mood, "오늘 힘든 하루였어요")
    }

    // MARK: - Test Case 5: 다른 사용자는 독립적인 Rate Limit

    func testDifferentUsers_IndependentRateLimits() async throws {
        // Given
        spyRateLimiterRepository.shouldAllow = true
        spyAIRepository.generatedVerse = GeneratedVerse(
            verse: Verse(book: "시편", chapter: 1, verse: 1, text: "복 있는 사람", translation: "개역개정"),
            reason: "테스트"
        )

        // When: 두 명의 다른 사용자가 요청
        _ = try await useCase.execute(normalizedText: "텍스트1", userId: "user123", timeZone: .current)
        _ = try await useCase.execute(normalizedText: "텍스트2", userId: "user456", timeZone: .current)

        // Then: 각각 다른 키로 daily limit 체크
        XCTAssertEqual(spyRateLimiterRepository.checkDailyCallCount, 2)
        // 마지막 호출된 키 확인
        XCTAssertEqual(spyRateLimiterRepository.lastDailyKey, "generate_verse:user456")
    }
}

// MARK: - Test Doubles (Spy pattern)

final class SpyAIRepository: AIRepository {
    var generateVerseCallCount = 0
    var lastRequest: AIGenerateVerseRequest?
    var generatedVerse: GeneratedVerse?
    var shouldBlockContent = false
    var blockReason = ""

    func generateVerse(_ request: AIGenerateVerseRequest) async throws -> GeneratedVerse {
        generateVerseCallCount += 1
        lastRequest = request

        if shouldBlockContent {
            throw AIRepositoryError.contentBlocked(reason: blockReason)
        }

        guard let verse = generatedVerse else {
            throw AIRepositoryError.invalidResponse
        }

        return verse
    }
}

final class SpyRateLimiterRepository: RateLimiterRepository {
    var checkCallCount = 0
    var lastKey: String?
    var lastMax: Int?
    var lastPer: TimeInterval?
    var checkDailyCallCount = 0
    var lastDailyKey: String?
    var lastDate: Date?
    var lastTimeZone: TimeZone?
    var shouldAllow = true

    func checkAndConsume(key: String, max: Int, per: TimeInterval) async throws -> Bool {
        checkCallCount += 1
        lastKey = key
        lastMax = max
        lastPer = per
        return shouldAllow
    }

    func checkDailyLimit(key: String, date: Date, timeZone: TimeZone) async throws -> Bool {
        checkDailyCallCount += 1
        lastDailyKey = key
        lastDate = date
        lastTimeZone = timeZone
        return shouldAllow
    }
}
