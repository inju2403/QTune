//
//  RequestVerseState.swift
//  QTune
//
//  Created by 이승주 on 7/26/25.
//

import Foundation
import Domain

public struct RequestVerseState: Equatable {
    // 입력
    var moodText: String = ""        // 감정/상황 (필수)
    var noteText: String = ""        // 추가 메모 (선택)

    // 상태
    var isLoading: Bool = false
    var errorMessage: String? = nil

    // 결과
    var generatedResult: GeneratedVerseResult? = nil

    // Draft
    var todayDraft: QuietTime? = nil
    var showDraftBanner: Bool = false
    var showDraftConflict: Bool = false

    /// 입력값 검증
    var isValidInput: Bool {
        !moodText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 결과가 있는지 여부
    var hasResult: Bool {
        generatedResult != nil
    }
}

/// 생성된 말씀 결과
public struct GeneratedVerseResult: Equatable, Hashable {
    public let verseRef: String        // 예: "시편 23:1"
    public let verseText: String       // 말씀 본문
    public let verseTextEN: String?    // 영어 텍스트 (선택)
    public let korean: String          // 한글 해설 (GPT 생성, 3~5문장)
    public let rationale: String       // 추천 이유
    public let verse: Verse            // Domain 모델 (QT 작성 화면으로 전달용)
    public let isSafe: Bool            // safety 검증 결과 (차단되지 않았는지)

    public init(verseRef: String, verseText: String, verseTextEN: String?, korean: String, rationale: String, verse: Verse, isSafe: Bool) {
        self.verseRef = verseRef
        self.verseText = verseText
        self.verseTextEN = verseTextEN
        self.korean = korean
        self.rationale = rationale
        self.verse = verse
        self.isSafe = isSafe
    }
}
