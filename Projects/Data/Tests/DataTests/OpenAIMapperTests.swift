//
//  OpenAIMapperTests.swift
//  DataTests
//
//  Created by Claude Code on 10/11/25.
//

import XCTest
@testable import Data
@testable import Domain

final class OpenAIMapperTests: XCTestCase {

    // MARK: - Test Case 1: 정상적인 한글 구절 매핑

    func testToDomain_KoreanVerse_Success() throws {
        // Given
        let dto = GeneratedVerseDTO(
            verseRef: "시편 23:1",
            verseText: "여호와는 나의 목자시니 내게 부족함이 없으리로다",
            verseTextEN: "The LORD is my shepherd; I shall not want.",
            rationale: "힘든 시간을 보내시는 당신에게 위로가 되길 바랍니다.",
            tags: ["위로", "감사"],
            safety: Safety(status: "ok", code: 0, reason: "정상 처리되었습니다")
        )

        // When
        let result = try OpenAIMapper.toDomain(dto)

        // Then
        XCTAssertEqual(result.verse.book, "시편")
        XCTAssertEqual(result.verse.chapter, 23)
        XCTAssertEqual(result.verse.verse, 1)
        XCTAssertEqual(result.verse.text, "여호와는 나의 목자시니 내게 부족함이 없으리로다")
        XCTAssertEqual(result.verse.translation, "개역개정")
        XCTAssertEqual(result.reason, "힘든 시간을 보내시는 당신에게 위로가 되길 바랍니다.")
    }

    // MARK: - Test Case 2: 영어 구절 매핑

    func testToDomain_EnglishVerse_Success() throws {
        // Given
        let dto = GeneratedVerseDTO(
            verseRef: "John 3:16",
            verseText: "For God so loved the world that he gave his one and only Son.",
            verseTextEN: "For God so loved the world that he gave his one and only Son.",
            rationale: "God's love is eternal.",
            tags: ["love", "salvation"],
            safety: Safety(status: "ok", code: 0, reason: "Processed successfully")
        )

        // When
        let result = try OpenAIMapper.toDomain(dto)

        // Then
        XCTAssertEqual(result.verse.book, "John")
        XCTAssertEqual(result.verse.chapter, 3)
        XCTAssertEqual(result.verse.verse, 16)
        XCTAssertEqual(result.verse.text, "For God so loved the world that he gave his one and only Son.")
        XCTAssertEqual(result.verse.translation, "NIV")
        XCTAssertEqual(result.reason, "God's love is eternal.")
    }

    // MARK: - Test Case 3: 여러 단어로 된 책명

    func testToDomain_MultiWordBook_Success() throws {
        // Given
        let dto = GeneratedVerseDTO(
            verseRef: "고린도전서 13:4",
            verseText: "사랑은 오래 참고 사랑은 온유하며",
            verseTextEN: nil,
            rationale: "사랑의 의미를 되새겨보세요.",
            tags: ["사랑"],
            safety: Safety(status: "ok", code: 0, reason: "정상")
        )

        // When
        let result = try OpenAIMapper.toDomain(dto)

        // Then
        XCTAssertEqual(result.verse.book, "고린도전서")
        XCTAssertEqual(result.verse.chapter, 13)
        XCTAssertEqual(result.verse.verse, 4)
        XCTAssertEqual(result.verse.text, "사랑은 오래 참고 사랑은 온유하며")
        XCTAssertEqual(result.verse.translation, "개역개정")
    }

    // MARK: - Test Case 4: 잘못된 verseRef 형식

    func testToDomain_InvalidVerseRef_ThrowsError() throws {
        // Given: 잘못된 형식의 verseRef
        let dto = GeneratedVerseDTO(
            verseRef: "Invalid Format",
            verseText: "Some text",
            verseTextEN: nil,
            rationale: "Some reason",
            tags: nil,
            safety: Safety(status: "ok", code: 0, reason: "ok")
        )

        // When/Then
        XCTAssertThrowsError(try OpenAIMapper.toDomain(dto)) { error in
            guard case OpenAIMapper.MapperError.invalidVerseRef(let ref) = error else {
                XCTFail("Expected invalidVerseRef error")
                return
            }
            XCTAssertEqual(ref, "Invalid Format")
        }
    }

    // MARK: - Test Case 5: 잘못된 장:절 형식

    func testToDomain_InvalidChapterVerse_ThrowsError() throws {
        // Given: 장:절이 없는 형식
        let dto = GeneratedVerseDTO(
            verseRef: "시편 23",
            verseText: "Some text",
            verseTextEN: nil,
            rationale: "Some reason",
            tags: nil,
            safety: Safety(status: "ok", code: 0, reason: "ok")
        )

        // When/Then
        XCTAssertThrowsError(try OpenAIMapper.toDomain(dto)) { error in
            guard case OpenAIMapper.MapperError.invalidVerseRef = error else {
                XCTFail("Expected invalidVerseRef error")
                return
            }
        }
    }
}
