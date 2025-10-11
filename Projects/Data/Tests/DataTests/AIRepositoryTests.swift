//
//  AIRepositoryTests.swift
//  DataTests
//
//  Created by Claude Code on 10/11/25.
//

import XCTest
@testable import Data
@testable import Domain

final class AIRepositoryTests: XCTestCase {
    var repository: DefaultAIRepository!
    var spyDataSource: SpyOpenAIRemoteDataSource!

    override func setUp() {
        super.setUp()
        spyDataSource = SpyOpenAIRemoteDataSource()
        repository = DefaultAIRepository(remoteDataSource: spyDataSource)
    }

    override func tearDown() {
        repository = nil
        spyDataSource = nil
        super.tearDown()
    }

    // MARK: - Test Case 1: 정상 생성 (safety.status = ok)

    func testGenerateVerse_Success() async throws {
        // Given: safety.status = "ok"
        spyDataSource.generatedDTO = GeneratedVerseDTO(
            verseRef: "시편 23:1",
            verseText: "여호와는 나의 목자시니 내게 부족함이 없으리로다",
            verseTextEN: "The LORD is my shepherd; I shall not want.",
            rationale: "위로가 필요한 순간입니다.",
            tags: ["위로"],
            safety: Safety(status: "ok", code: 0, reason: "정상 처리되었습니다")
        )

        // When
        let request = AIGenerateVerseRequest(
            locale: "ko_KR",
            mood: "오늘 힘든 하루였어요",
            note: nil
        )
        let result = try await repository.generateVerse(request)

        // Then: 정상적으로 Domain 모델로 변환됨
        XCTAssertEqual(result.verse.book, "시편")
        XCTAssertEqual(result.verse.chapter, 23)
        XCTAssertEqual(result.verse.verse, 1)
        XCTAssertEqual(result.reason, "위로가 필요한 순간입니다.")

        // Verify: DataSource가 호출되었는지 확인
        XCTAssertEqual(spyDataSource.generateCallCount, 1)
        XCTAssertEqual(spyDataSource.lastRequest?.mood, "오늘 힘든 하루였어요")
    }

    // MARK: - Test Case 2: Content Blocked (safety.status = blocked)

    func testGenerateVerse_ContentBlocked_ThrowsError() async throws {
        // Given: safety.status = "blocked"
        spyDataSource.generatedDTO = GeneratedVerseDTO(
            verseRef: "",
            verseText: "",
            verseTextEN: nil,
            rationale: "",
            tags: nil,
            safety: Safety(status: "blocked", code: 1001, reason: "부적절한 콘텐츠가 감지되었습니다")
        )

        // When/Then
        let request = AIGenerateVerseRequest(
            locale: "ko_KR",
            mood: "욕설이 포함된 내용",
            note: nil
        )

        do {
            _ = try await repository.generateVerse(request)
            XCTFail("Expected contentBlocked error")
        } catch {
            guard case AIRepositoryError.contentBlocked(let reason) = error else {
                XCTFail("Expected contentBlocked, got \(error)")
                return
            }
            XCTAssertEqual(reason, "부적절한 콘텐츠가 감지되었습니다")
        }

        // Verify: DataSource가 호출되었는지 확인
        XCTAssertEqual(spyDataSource.generateCallCount, 1)
    }

    // MARK: - Test Case 3: Data Source 에러 전파

    func testGenerateVerse_DataSourceError_Propagates() async throws {
        // Given: DataSource가 에러를 던짐
        spyDataSource.shouldThrowError = OpenAIDataSourceError.invalidJSON

        // When/Then
        let request = AIGenerateVerseRequest(
            locale: "ko_KR",
            mood: "테스트",
            note: nil
        )

        do {
            _ = try await repository.generateVerse(request)
            XCTFail("Expected error")
        } catch {
            // 에러가 전파되어야 함
            XCTAssertTrue(error is OpenAIDataSourceError)
        }
    }
}

// MARK: - Test Doubles (Spy pattern)

final class SpyOpenAIRemoteDataSource: OpenAIRemoteDataSource {
    var generateCallCount = 0
    var lastRequest: GenerateVerseRequest?
    var generatedDTO: GeneratedVerseDTO?
    var shouldThrowError: Error?

    func generate(_ request: GenerateVerseRequest) async throws -> GeneratedVerseDTO {
        generateCallCount += 1
        lastRequest = request

        if let error = shouldThrowError {
            throw error
        }

        guard let dto = generatedDTO else {
            throw OpenAIDataSourceError.emptyResponse
        }

        return dto
    }
}
