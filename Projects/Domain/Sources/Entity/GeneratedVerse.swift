//
//  GeneratedVerse.swift
//  QTune
//
//  Created by 이승주 on 7/26/25.
//

import Foundation

public struct GeneratedVerse: Equatable {
    public let verse: Verse
    public let secondaryVerse: Verse?   // 비교 역본 말씀 (선택)
    public let korean: String           // GPT 한글 해설 (3~5문장)
    public let reason: String           // 추천 이유 (1~2문장)

    public init(verse: Verse, secondaryVerse: Verse? = nil, korean: String, reason: String) {
        self.verse = verse
        self.secondaryVerse = secondaryVerse
        self.korean = korean
        self.reason = reason
    }
}
