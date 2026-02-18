//
//  DefaultFetchVerseDirectUseCase.swift
//  Data
//
//  Created by 이승주 on 2/18/26.
//

import Foundation
import Domain

/// 구절 직접 조회 UseCase 구현체
public final class DefaultFetchVerseDirectUseCase: FetchVerseDirectUseCase {
    private let bibleDataSource: BibleAPIDataSource

    public init(bibleDataSource: BibleAPIDataSource) {
        self.bibleDataSource = bibleDataSource
    }

    public func execute(verseRef: String, translation: String) async throws -> Verse {
        // 한글 책명을 영어 책명으로 정규화
        let normalizedRef = Self.normalizeVerseRef(verseRef)
        let dto = try await bibleDataSource.getVerseWithTranslation(verseRef: normalizedRef, translation: translation)

        // verseRef 파싱: "Psalms 37:5-6" → book, chapter, verse
        let parts = normalizedRef.split(separator: " ")
        guard parts.count >= 2 else {
            throw NSError(domain: "FetchVerseDirect", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid verse reference: \(verseRef)"])
        }

        let book = parts.dropLast().joined(separator: " ")
        let chapterVerse = String(parts.last!)
        let cvParts = chapterVerse.split(separator: ":")

        guard cvParts.count == 2, let chapter = Int(cvParts[0]) else {
            throw NSError(domain: "FetchVerseDirect", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid chapter format"])
        }

        let verseStr = String(cvParts[1])
        let startVerse = Int(verseStr.split(separator: "-").first.map(String.init) ?? verseStr) ?? 1

        return Verse(
            book: book,
            chapter: chapter,
            verse: startVerse,
            text: dto.text,
            translation: translation
        )
    }

    /// 한글 책명을 영어 책명으로 정규화
    /// "시편 37:5" → "Psalms 37:5", "요한복음 3:16-18" → "John 3:16-18"
    static func normalizeVerseRef(_ ref: String) -> String {
        let trimmed = ref.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: " ")
        guard parts.count >= 2 else { return trimmed }

        // 마지막 파트가 chapter:verse 형식인지 확인
        let lastPart = String(parts.last!)
        guard lastPart.contains(":") else { return trimmed }

        let bookPart = parts.dropLast().joined(separator: " ")

        // 한글 책명이면 영어로 변환
        if let english = BibleBookMapper.toEnglishName(bookPart) {
            return "\(english) \(lastPart)"
        }
        return trimmed
    }
}
