//
//  Verse.swift
//  QTune
//
//  Created by 이승주 on 7/26/25.
//

import Foundation

public struct Verse: Equatable {
    var id: String { "\(book) \(chapter):\(verse)" }

    let book: String            // 성경 책 이름, 예: "John"
    let chapter: Int            // 장 번호, 예: 3
    let verse: Int              // 절 번호, 예: 16
    let text: String            // 말씀 본문, 예: "For God so loved the world..."
    let translation: String      // 번역본, 예: "KJV", "NIV", "개역개정"

    public init(book: String, chapter: Int, verse: Int, text: String, translation: String) {
        self.book = book
        self.chapter = chapter
        self.verse = verse
        self.text = text
        self.translation = translation
    }
}
