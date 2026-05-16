//
//  BibleAPIDataSource.swift
//  Data
//
//  Created by 이승주 on 10/11/25.
//

import Foundation

/// Bible API DTO (bible-api.com 응답)
public struct BibleVerseDTO: Codable {
    public let reference: String    // "John 3:16"
    public let text: String         // 영어 본문 또는 한국어 본문
    public let translation_id: String?  // "web", "kjv", "KRV" 등
    public let translation_name: String?

    enum CodingKeys: String, CodingKey {
        case reference
        case text
        case translation_id
        case translation_name
    }
}

/// bolls.life API 응답 (배열)
private struct BollsVerseResponse: Codable {
    let pk: Int
    let verse: Int
    let text: String
}

/// Bible API DataSource
public final class BibleAPIDataSource {
    private let client: HTTPClient

    public init(client: HTTPClient) {
        self.client = client
    }

    /// 영어 본문 가져오기 (WEB 우선, KJV 폴백)
    /// 번들된 로컬 DB 를 먼저 조회하고, 실패 시 네트워크로 폴백한다.
    public func getVerse(verseRef: String) async throws -> BibleVerseDTO {
        if let local = localVerseDTO(verseRef: verseRef, translation: "WEB") {
            return local
        }
        if let local = localVerseDTO(verseRef: verseRef, translation: "KJV") {
            return local
        }

        do {
            return try await fetchVerse(verseRef: verseRef, translation: "web")
        } catch {
            return try await fetchVerse(verseRef: verseRef, translation: "kjv")
        }
    }

    /// 특정 역본으로 본문 가져오기
    /// 번들된 로컬 DB 를 먼저 조회하고, 실패 시 네트워크(KRV→bolls.life, 기타→bible-api.com)로 폴백.
    public func getVerseWithTranslation(verseRef: String, translation: String) async throws -> BibleVerseDTO {
        if let local = localVerseDTO(verseRef: verseRef, translation: translation) {
            return local
        }

        if translation.uppercased() == "KRV" {
            return try await fetchFromBolls(verseRef: verseRef)
        }

        return try await fetchVerse(verseRef: verseRef, translation: translation.lowercased())
    }

    /// 번들 DB 조회 → DTO 매핑. 책 미매핑/장절 파싱 실패/미스는 nil.
    private func localVerseDTO(verseRef: String, translation: String) -> BibleVerseDTO? {
        guard let parsed = parseVerseRef(verseRef) else { return nil }
        guard let bookId = BibleBookMapper.toBookId(parsed.book) else { return nil }
        guard let text = BibleLocalDB.shared.getVerseText(
            bookId: bookId,
            chapter: parsed.chapter,
            startVerse: parsed.startVerse,
            endVerse: parsed.endVerse,
            translation: translation
        ) else { return nil }

        let trUpper = translation.uppercased()
        let name: String
        switch trUpper {
        case "KRV": name = "개역한글"
        case "WEB": name = "World English Bible"
        case "KJV": name = "King James Version"
        default: name = trUpper
        }
        return BibleVerseDTO(
            reference: verseRef,
            text: text,
            translation_id: trUpper,
            translation_name: name
        )
    }

    /// "John 3:16" / "1 Corinthians 13:4-7" 형식의 ref 를 책/장/시작절/끝절로 분해.
    private func parseVerseRef(_ verseRef: String) -> (book: String, chapter: Int, startVerse: Int, endVerse: Int)? {
        let components = verseRef.split(separator: " ")
        guard components.count >= 2 else { return nil }

        let book = components[0..<components.count-1].joined(separator: " ")
        let chapterVerse = String(components.last!)
        let cv = chapterVerse.split(separator: ":")
        guard cv.count == 2, let chapter = Int(cv[0]) else { return nil }

        let verseString = String(cv[1])
        if let dashIndex = verseString.firstIndex(of: "-") {
            let startStr = String(verseString[..<dashIndex])
            let endStr = String(verseString[verseString.index(after: dashIndex)...])
            guard let start = Int(startStr), let end = Int(endStr) else { return nil }
            return (book, chapter, start, end)
        } else {
            guard let v = Int(verseString) else { return nil }
            return (book, chapter, v, v)
        }
    }

    /// bolls.life API에서 한국어 성경 가져오기
    private func fetchFromBolls(verseRef: String) async throws -> BibleVerseDTO {
        // verseRef 파싱: "John 3:16" → book="John", chapter=3, verse=16
        let components = verseRef.split(separator: " ")
        guard components.count >= 2 else {
            throw NSError(domain: "BibleAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid verse reference"])
        }

        let book = components[0..<components.count-1].joined(separator: " ")
        let chapterVerse = String(components.last!)

        let chapterVerseComponents = chapterVerse.split(separator: ":")
        guard chapterVerseComponents.count == 2,
              let chapter = Int(chapterVerseComponents[0]) else {
            throw NSError(domain: "BibleAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid chapter:verse format"])
        }

        // 절 파싱 (범위인 경우 시작과 끝 절 모두 처리)
        let verseString = String(chapterVerseComponents[1])
        let startVerse: Int
        let endVerse: Int

        if let dashIndex = verseString.firstIndex(of: "-") {
            // 범위인 경우 (예: "6-7")
            let startStr = String(verseString[..<dashIndex])
            let endStr = String(verseString[verseString.index(after: dashIndex)...])
            guard let start = Int(startStr), let end = Int(endStr) else {
                throw NSError(domain: "BibleAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid verse range format"])
            }
            startVerse = start
            endVerse = end
        } else {
            // 단일 절인 경우
            guard let verse = Int(verseString) else {
                throw NSError(domain: "BibleAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid verse format"])
            }
            startVerse = verse
            endVerse = verse
        }

        // 책명을 bolls.life 약어로 변환
        guard let bookCode = BibleBookMapper.toBollsCode(book) else {
            throw NSError(domain: "BibleAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown book name: \(book)"])
        }

        // bolls.life API 호출: https://bolls.life/get-text/KRV/{book}/{chapter}/
        let urlString = "https://bolls.life/get-text/KRV/\(bookCode)/\(chapter)/"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "BibleAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let verses = try JSONDecoder().decode([BollsVerseResponse].self, from: data)

        // 범위의 모든 절 가져오기
        let selectedVerses = verses.filter { $0.verse >= startVerse && $0.verse <= endVerse }
        guard !selectedVerses.isEmpty else {
            throw NSError(domain: "BibleAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Verses \(startVerse)-\(endVerse) not found"])
        }

        // 여러 절을 하나의 텍스트로 합치기
        let combinedText = selectedVerses
            .sorted { $0.verse < $1.verse }
            .map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
            .joined(separator: " ")

        return BibleVerseDTO(
            reference: verseRef,
            text: combinedText,
            translation_id: "KRV",
            translation_name: "개역한글"
        )
    }

    private func fetchVerse(verseRef: String, translation: String) async throws -> BibleVerseDTO {
        // URLComponents가 자동으로 인코딩하므로 여기서는 인코딩하지 않음
        let endpoint = Endpoint<EmptyRequest, BibleVerseDTO>(
            path: "/\(verseRef)",
            method: .get,
            queryItems: [URLQueryItem(name: "translation", value: translation)]
        )

        // GET 요청은 body를 nil로 전달
        let dto = try await client.request(endpoint, body: nil, headers: [:])
        // WEB/KJV 텍스트의 끝 개행문자 제거 - 새 DTO 생성
        let trimmedDTO = BibleVerseDTO(
            reference: dto.reference,
            text: dto.text.trimmingCharacters(in: .whitespacesAndNewlines),
            translation_id: dto.translation_id,
            translation_name: dto.translation_name
        )
        return trimmedDTO
    }
}
