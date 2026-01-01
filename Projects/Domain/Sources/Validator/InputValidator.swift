//
//  InputValidator.swift
//  Domain
//
//  Created by 이승주 on 10/11/25.
//

import Foundation

/// 입력 검증 에러
public enum InputValidationError: Error {
    case tooLong(maxLength: Int)
    case tooShort(minLength: Int)
    case containsSpam
    case containsForbiddenContent
}

/// 입력 검증 유틸리티
public struct InputValidator {

    private static let maxInputLength = 500  // 최대 500자
    private static let minInputLength = 2    // 최소 2자

    // 스팸 패턴 (URL이 과도하게 포함된 경우)
    private static let urlPattern = try! NSRegularExpression(
        pattern: "https?://[\\w\\-.]+",
        options: .caseInsensitive
    )

    /// 사용자 입력(mood/note) 검증
    public static func validate(mood: String, note: String?) throws {
        let combinedText = [mood, note].compactMap { $0 }.joined(separator: " ")

        // 1. 길이 검증
        guard combinedText.count >= minInputLength else {
            throw InputValidationError.tooShort(minLength: minInputLength)
        }

        guard combinedText.count <= maxInputLength else {
            throw InputValidationError.tooLong(maxLength: maxInputLength)
        }

        // 2. URL 스팸 검증 (3개 이상의 URL이 포함되면 스팸으로 간주)
        let urlMatches = urlPattern.matches(
            in: combinedText,
            range: NSRange(combinedText.startIndex..., in: combinedText)
        )

        if urlMatches.count >= 3 {
            throw InputValidationError.containsSpam
        }

        // 3. 금칙어 검증 (간단한 예시)
        // 실제 프로덕션에서는 더 정교한 필터링 필요
        let forbiddenKeywords = ["test_forbidden", "spam_keyword"]
        for keyword in forbiddenKeywords {
            if combinedText.lowercased().contains(keyword) {
                throw InputValidationError.containsForbiddenContent
            }
        }
    }
}
