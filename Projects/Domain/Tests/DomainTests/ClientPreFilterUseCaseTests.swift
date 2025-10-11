//
//  ClientPreFilterUseCaseTests.swift
//  DomainTests
//
//  Created by 이승주 on 10/8/25.
//

import XCTest
@testable import Domain

final class ClientPreFilterUseCaseTests: XCTestCase {
    var useCase: ClientPreFilterUseCase!

    override func setUp() {
        super.setUp()
        useCase = ClientPreFilterUseCase()
    }

    override func tearDown() {
        useCase = nil
        super.tearDown()
    }

    // MARK: - Test Case 1: 공백/제로폭만 → block(empty_after_normalize)

    func testEmptyAfterNormalize_Blocked() {
        // Given: 공백과 제로폭 문자만
        let inputs = [
            "   ",
            "\n\n\n",
            "\t\t\t",
            "\u{200B}\u{FEFF}",
            "  \n  \t  ",
        ]

        for input in inputs {
            // When
            let result = useCase.execute(rawText: input)

            // Then
            XCTAssertTrue(result.isBlocked, "Input: '\(input)'")
            XCTAssertEqual(result.normalizedText, "")
            XCTAssertEqual(result.verdict.code, "empty_after_normalize")
            XCTAssertTrue(result.codes.contains("empty_after_normalize"))
        }
    }

    // MARK: - Test Case 2: 501자 → needsReview(len_truncated) + 500자

    func testOverMaxLength_Truncated() {
        // Given: 501자 텍스트
        let longText = String(repeating: "가", count: 501)

        // When
        let result = useCase.execute(rawText: longText)

        // Then
        XCTAssertEqual(result.normalizedText.count, 500)
        XCTAssertTrue(result.needsWarning)
        XCTAssertEqual(result.verdict.code, "len_truncated")
        XCTAssertTrue(result.codes.contains("len_truncated"))
        XCTAssertTrue(result.hints.contains(where: { $0.messageKey == "warning.text_truncated" }))
    }

    // MARK: - Test Case 3: "ㅋㅋㅋㅋㅋㅋ" → "ㅋㅋ" + needsReview(meaningless_repetition)

    func testMeaninglessRepetition_Detected() {
        // Given: 의미 없는 반복
        let inputs = [
            ("ㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋ", "ㅋㅋ"),
            ("!!!!!!!!!!", "!!"),
            ("ㅎㅎㅎㅎㅎ", "ㅎㅎ"),
        ]

        for (input, expected) in inputs {
            // When
            let result = useCase.execute(rawText: input)

            // Then
            XCTAssertEqual(result.normalizedText, expected, "Input: '\(input)'")
            XCTAssertTrue(result.needsWarning, "Input: '\(input)'")
            XCTAssertTrue(result.codes.contains("meaningless_repetition"), "Input: '\(input)'")
        }
    }

    // MARK: - Test Case 4: URL 포함 → needsReview(url_or_contact_detected)

    func testURLDetection_NeedsReview() {
        // Given: URL 포함 텍스트
        let inputs = [
            "자세한 내용은 https://example.com 에서 확인하세요",
            "www.naver.com 방문해주세요",
            "연락처: 010-1234-5678",
            "카톡으로 연락주세요",
        ]

        for input in inputs {
            // When
            let result = useCase.execute(rawText: input)

            // Then
            XCTAssertTrue(result.needsWarning, "Input: '\(input)'")
            XCTAssertTrue(result.codes.contains("url_or_contact_detected"), "Input: '\(input)'")
            XCTAssertTrue(result.hints.contains(where: { $0.messageKey == "warning.url_or_contact" }), "Input: '\(input)'")
        }
    }

    // MARK: - Test Case 5: 제어문자만 → block(only_control_chars)

    func testOnlyControlChars_Blocked() {
        // Given: 제어문자만 (C0/C1)
        let inputs = [
            "\u{0000}\u{0001}\u{0002}",
            "\u{0080}\u{0081}\u{0082}",
            "\u{001F}\u{009F}",
        ]

        for input in inputs {
            // When
            let result = useCase.execute(rawText: input)

            // Then
            XCTAssertTrue(result.isBlocked, "Input with control chars")
            XCTAssertEqual(result.verdict.code, "only_control_chars")
            XCTAssertTrue(result.codes.contains("only_control_chars"))
        }
    }

    // MARK: - Test Case 6: 정상 문장 → allow

    func testNormalText_Allowed() {
        // Given: 정상적인 문장들
        let inputs = [
            "오늘은 힘든 하루였어요",
            "하나님께 감사드립니다",
            "시험이 걱정되네요",
            "Today was a great day!",
            "내일 면접이 있어서 불안해요. 도와주세요.",
        ]

        for input in inputs {
            // When
            let result = useCase.execute(rawText: input)

            // Then
            XCTAssertEqual(result.verdict, .allow, "Input: '\(input)'")
            XCTAssertTrue(result.codes.isEmpty, "Input: '\(input)'")
        }
    }

    // MARK: - Additional Tests

    func testWhitespaceNormalization() {
        // Given: 다양한 공백 패턴
        let input = "오늘은    매우\t\t힘든\n\n\n하루였어요"

        // When
        let result = useCase.execute(rawText: input)

        // Then
        XCTAssertEqual(result.normalizedText, "오늘은 매우 힘든\n\n하루였어요")
        XCTAssertEqual(result.verdict, .allow)
    }

    func testMinLength_Blocked() {
        // Given: 빈 문자열
        let input = ""

        // When
        let result = useCase.execute(rawText: input, config: PreFilterConfig(minLen: 1))

        // Then
        XCTAssertTrue(result.isBlocked)
    }

    func testZeroWidthRemoval() {
        // Given: 제로폭 문자 포함
        let input = "안녕\u{200B}하세요\u{FEFF}"

        // When
        let result = useCase.execute(rawText: input)

        // Then
        XCTAssertEqual(result.normalizedText, "안녕하세요")
        XCTAssertEqual(result.verdict, .allow)
    }

    func testMostlySymbols_NeedsReview() {
        // Given: 대부분 기호/이모지
        let input = "😀😁😂🤣😃😄😅"

        // When
        let result = useCase.execute(rawText: input)

        // Then
        XCTAssertTrue(result.needsWarning)
        XCTAssertTrue(result.codes.contains("gibberish_or_symbols"))
    }

    func testRepeatReduction() {
        // Given: 과도한 반복
        let input = "정말정말정말정말정말 좋아요"

        // When
        let result = useCase.execute(rawText: input, config: PreFilterConfig(reduceRepeatThreshold: 4))

        // Then
        // 반복 축약이 적용됨
        XCTAssertTrue(result.normalizedText.count < input.count)
    }
}
