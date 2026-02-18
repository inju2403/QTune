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
        let verseParts = verseStr.split(separator: "-")
        let startVerse = Int(verseParts.first.map(String.init) ?? verseStr) ?? 1
        let endVerse = verseParts.count > 1 ? Int(String(verseParts[1])) : nil

        return Verse(
            book: book,
            chapter: chapter,
            verse: startVerse,
            endVerse: endVerse,
            text: dto.text,
            translation: translation
        )
    }

    /// 한글 책명을 영어 책명으로 정규화
    /// "시편 37:5" → "Psalms 37:5", "시37:5" → "Psalms 37:5", "요한복음 3:16-18" → "John 3:16-18"
    static func normalizeVerseRef(_ ref: String) -> String {
        let trimmed = ref.trimmingCharacters(in: .whitespacesAndNewlines)

        // 1차: 공백 기준 분리 ("시 37:5", "Psalms 37:5")
        let parts = trimmed.split(separator: " ")
        if parts.count >= 2 {
            let lastPart = String(parts.last!)
            if lastPart.contains(":") {
                let bookPart = parts.dropLast().joined(separator: " ")
                if let english = BibleBookMapper.toEnglishName(bookPart) {
                    return "\(english) \(lastPart)"
                }
                return trimmed
            }
        }

        // 2차: 공백 없이 붙여쓴 경우 정규식으로 분리 ("시37:5", "요한복음3:16-18")
        // 패턴: 책명(한글/영문 등) + 숫자:숫자(-숫자)?
        if let (bookPart, chapterVerse) = splitBookAndChapterVerse(trimmed) {
            let trimmedBook = bookPart.trimmingCharacters(in: .whitespaces)
            if let english = BibleBookMapper.toEnglishName(trimmedBook) {
                return "\(english) \(chapterVerse)"
            }
            // 이미 영어 책명인 경우 ("John3:16" → "John 3:16")
            if !trimmedBook.isEmpty {
                return "\(trimmedBook) \(chapterVerse)"
            }
        }

        return trimmed
    }

    /// 정규식으로 책명과 장:절을 분리
    /// "시37:5" → ("시", "37:5"), "요한복음3:16-18" → ("요한복음", "3:16-18")
    private static func splitBookAndChapterVerse(_ ref: String) -> (String, String)? {
        let pattern = #"^(.+?)(\d+:\d+(?:-\d+)?)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: ref, range: NSRange(ref.startIndex..., in: ref)),
              match.numberOfRanges == 3,
              let bookRange = Range(match.range(at: 1), in: ref),
              let cvRange = Range(match.range(at: 2), in: ref)
        else { return nil }

        return (String(ref[bookRange]), String(ref[cvRange]))
    }
}
