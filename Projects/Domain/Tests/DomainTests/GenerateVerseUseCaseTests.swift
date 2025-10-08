//
//  GenerateVerseInteractorTests.swift
//  DomainTests
//
//  Created by Claude Code on 10/8/25.
//

import XCTest
@testable import Domain

final class GenerateVerseUseCaseTests: XCTestCase {
    var useCase: GenerateVerseInteractor!
    var mockVerseRepository: MockVerseRepository!
    var mockRateLimiterRepository: MockRateLimiterRepository!
    var mockModerationRepository: MockModerationRepository!

    override func setUp() {
        super.setUp()
        mockVerseRepository = MockVerseRepository()
        mockRateLimiterRepository = MockRateLimiterRepository()
        mockModerationRepository = MockModerationRepository()
        useCase = GenerateVerseInteractor(
            verseRepository: mockVerseRepository,
            rateLimiterRepository: mockRateLimiterRepository,
            moderationRepository: mockModerationRepository,
            maxRequestsPerHour: 10
        )
    }

    override func tearDown() {
        useCase = nil
        mockVerseRepository = nil
        mockRateLimiterRepository = nil
        mockModerationRepository = nil
        super.tearDown()
    }

    // MARK: - Test Case 1: Rate Limit 초과 → DomainError.rateLimited

    func testRateLimitExceeded_ThrowsRateLimited() async throws {
        // Given: Rate Limit 초과 상태
        mockRateLimiterRepository.shouldAllow = false

        // When/Then
        do {
            _ = try await useCase.execute(normalizedText: "오늘 힘든 하루였어요", userId: "user123")
            XCTFail("Expected rateLimited error")
        } catch {
            guard case DomainError.rateLimited = error else {
                XCTFail("Expected rateLimited, got \(error)")
                return
            }
            // Success
        }

        // Verify: Rate limiter가 호출되었는지 확인
        XCTAssertEqual(mockRateLimiterRepository.checkCallCount, 1)
        XCTAssertEqual(mockRateLimiterRepository.lastKey, "generate_verse:user123")
        XCTAssertEqual(mockRateLimiterRepository.lastMax, 10)
        XCTAssertEqual(mockRateLimiterRepository.lastPer, 3600)

        // Verify: Moderation과 Verse 생성은 호출되지 않았는지 확인
        XCTAssertEqual(mockModerationRepository.analyzeCallCount, 0)
        XCTAssertEqual(mockVerseRepository.generateCallCount, 0)
    }

    // MARK: - Test Case 2: Moderation Blocked → DomainError.moderationBlocked

    func testModerationBlocked_ThrowsModerationBlocked() async throws {
        // Given: Rate Limit 통과, Moderation Blocked
        mockRateLimiterRepository.shouldAllow = true
        mockModerationRepository.verdict = .blocked(reason: "inappropriate_content")

        // When/Then
        do {
            _ = try await useCase.execute(normalizedText: "부적절한 내용", userId: "user123")
            XCTFail("Expected moderationBlocked error")
        } catch {
            guard case DomainError.moderationBlocked(let reason) = error else {
                XCTFail("Expected moderationBlocked, got \(error)")
                return
            }
            XCTAssertEqual(reason, "inappropriate_content")
        }

        // Verify: Rate limiter와 Moderation이 호출되었는지 확인
        XCTAssertEqual(mockRateLimiterRepository.checkCallCount, 1)
        XCTAssertEqual(mockModerationRepository.analyzeCallCount, 1)
        XCTAssertEqual(mockModerationRepository.lastText, "부적절한 내용")

        // Verify: Verse 생성은 호출되지 않았는지 확인
        XCTAssertEqual(mockVerseRepository.generateCallCount, 0)
    }

    // MARK: - Test Case 3: Moderation NeedsReview → 진행 허용 (safe mode)

    func testModerationNeedsReview_Proceeds() async throws {
        // Given: Rate Limit 통과, Moderation NeedsReview
        mockRateLimiterRepository.shouldAllow = true
        mockModerationRepository.verdict = .needsReview(reason: "borderline_content")
        mockVerseRepository.generatedVerse = GeneratedVerse(
            verse: Verse(
                book: "잠언",
                chapter: 3,
                verse: 5,
                text: "너는 마음을 다하여 여호와를 신뢰하고 네 명철을 의지하지 말라",
                translation: "개역개정"
            ),
            reason: "의심스러운 내용이 감지되었으나 안전 모드로 생성되었습니다"
        )

        // When
        let result = try await useCase.execute(normalizedText: "애매한 내용", userId: "user123")

        // Then: 정상 진행 (서버가 safe mode로 처리)
        XCTAssertEqual(result.verse.book, "잠언")
        XCTAssertEqual(result.verse.chapter, 3)
        XCTAssertEqual(result.verse.verse, 5)
        XCTAssertTrue(result.reason.contains("안전 모드"))

        // Verify: 모든 단계가 호출되었는지 확인
        XCTAssertEqual(mockRateLimiterRepository.checkCallCount, 1)
        XCTAssertEqual(mockModerationRepository.analyzeCallCount, 1)
        XCTAssertEqual(mockVerseRepository.generateCallCount, 1)
        XCTAssertEqual(mockVerseRepository.lastPrompt, "애매한 내용")
    }

    // MARK: - Test Case 4: Moderation Allowed → 정상 생성

    func testModerationAllowed_GeneratesVerse() async throws {
        // Given: 모든 검증 통과
        mockRateLimiterRepository.shouldAllow = true
        mockModerationRepository.verdict = .allowed
        mockVerseRepository.generatedVerse = GeneratedVerse(
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
        let result = try await useCase.execute(normalizedText: "오늘 힘든 하루였어요", userId: "user123")

        // Then
        XCTAssertEqual(result.verse.book, "시편")
        XCTAssertEqual(result.verse.chapter, 23)
        XCTAssertEqual(result.verse.verse, 1)
        XCTAssertEqual(result.verse.text, "여호와는 나의 목자시니 내게 부족함이 없으리로다")
        XCTAssertTrue(result.reason.contains("위로"))

        // Verify: 모든 단계가 순서대로 호출되었는지 확인
        XCTAssertEqual(mockRateLimiterRepository.checkCallCount, 1)
        XCTAssertEqual(mockModerationRepository.analyzeCallCount, 1)
        XCTAssertEqual(mockVerseRepository.generateCallCount, 1)
        XCTAssertEqual(mockVerseRepository.lastPrompt, "오늘 힘든 하루였어요")
    }

    // MARK: - Test Case 5: 다른 사용자는 독립적인 Rate Limit

    func testDifferentUsers_IndependentRateLimits() async throws {
        // Given
        mockRateLimiterRepository.shouldAllow = true
        mockModerationRepository.verdict = .allowed
        mockVerseRepository.generatedVerse = GeneratedVerse(
            verse: Verse(book: "시편", chapter: 1, verse: 1, text: "복 있는 사람", translation: "개역개정"),
            reason: "테스트"
        )

        // When: 두 명의 다른 사용자가 요청
        _ = try await useCase.execute(normalizedText: "텍스트1", userId: "user123")
        _ = try await useCase.execute(normalizedText: "텍스트2", userId: "user456")

        // Then: 각각 다른 키로 rate limit 체크
        XCTAssertEqual(mockRateLimiterRepository.checkCallCount, 2)
        // 마지막 호출된 키 확인
        XCTAssertEqual(mockRateLimiterRepository.lastKey, "generate_verse:user456")
    }
}

// MARK: - Mock Repositories

final class MockVerseRepository: VerseRepository {
    var generateCallCount = 0
    var lastPrompt: String?
    var generatedVerse: GeneratedVerse?
    var shouldThrowError: Error?

    func generate(prompt: String) async throws -> GeneratedVerse {
        generateCallCount += 1
        lastPrompt = prompt

        if let error = shouldThrowError {
            throw error
        }

        guard let verse = generatedVerse else {
            throw DomainError.unknown
        }

        return verse
    }
}

final class MockRateLimiterRepository: RateLimiterRepository {
    var checkCallCount = 0
    var lastKey: String?
    var lastMax: Int?
    var lastPer: TimeInterval?
    var shouldAllow = true

    func checkAndConsume(key: String, max: Int, per: TimeInterval) async throws -> Bool {
        checkCallCount += 1
        lastKey = key
        lastMax = max
        lastPer = per
        return shouldAllow
    }
}

final class MockModerationRepository: ModerationRepository {
    var analyzeCallCount = 0
    var lastText: String?
    var verdict: ModerationVerdict = .allowed

    func analyze(text: String) async throws -> ModerationReport {
        analyzeCallCount += 1
        lastText = text
        return ModerationReport(
            verdict: verdict,
            confidence: 0.95,
            categories: []
        )
    }
}
