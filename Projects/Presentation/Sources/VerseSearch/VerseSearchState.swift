//
//  VerseSearchState.swift
//  Presentation
//
//  Created by 이승주 on 2/18/26.
//

import Foundation
import Domain

/// 구절 직접 찾기 화면의 비즈니스 상태
public struct VerseSearchState: Equatable {
    // 입력
    var searchText: String = ""
    var selectedTranslation: Translation = .koreanRevisedVersion

    // 검색 상태
    var isLoading: Bool = false
    var errorMessage: String? = nil

    // 결과
    var result: Verse? = nil

    // 해설
    var isExplanationAvailable: Bool = false
    var explanation: String? = nil
    var isExplanationLoading: Bool = false
    var explanationError: String? = nil

    // 기도문
    var suggestedPrayer: String? = nil
    var isPrayerLoading: Bool = false
    var prayerError: String? = nil

    /// 입력값 검증 (예: "시편 37:5", "요 3:16")
    var isValidInput: Bool {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.contains(":")
    }

    /// 결과가 있는지 여부
    var hasResult: Bool {
        result != nil
    }
}
