//
//  OpenAIMapper.swift
//  Data
//
//  Created by 이승주 on 10/11/25.
//

import Foundation
import Domain

/// OpenAI DTO를 Domain 모델로 변환하는 Mapper
public enum OpenAIMapper {

    /// Mapper 에러
    public enum MapperError: Error {
        case invalidVerseRef(String)
    }

    /// GeneratedVerseDTO를 Domain의 GeneratedVerse로 변환
    public static func toDomain(_ dto: GeneratedVerseDTO) throws -> GeneratedVerse {
        // verseRef 파싱: "시편 23:1" → book: "시편", chapter: 23, verse: 1
        let (book, chapter, verse) = try parseVerseRef(dto.verseRef)

        // translation 추출 (locale에 따라 기본값 설정)
        let translation = extractTranslation(from: dto.verseRef)

        let verseEntity = Verse(
            book: book,
            chapter: chapter,
            verse: verse,
            text: dto.verseText,
            translation: translation
        )

        return GeneratedVerse(
            verse: verseEntity,
            reason: dto.rationale
        )
    }

    // MARK: - Private Methods

    /// verseRef를 파싱하여 (book, chapter, verse) 반환
    /// 예: "시편 23:1" → ("시편", 23, 1)
    /// 예: "John 3:16" → ("John", 3, 16)
    private static func parseVerseRef(_ ref: String) throws -> (book: String, chapter: Int, verse: Int) {
        // 공백으로 split하여 책명과 장:절 분리
        let components = ref.split(separator: " ")

        // 최소 2개 이상이어야 함 (책명과 장:절)
        guard components.count >= 2 else {
            throw MapperError.invalidVerseRef(ref)
        }

        // 책명은 마지막 컴포넌트를 제외한 나머지
        let bookComponents = components.dropLast()
        let book = bookComponents.joined(separator: " ")

        // 마지막 컴포넌트가 "장:절" 형식
        let chapterVerse = String(components.last!)
        let chapterVerseComponents = chapterVerse.split(separator: ":")

        guard chapterVerseComponents.count == 2,
              let chapter = Int(chapterVerseComponents[0]),
              let verse = Int(chapterVerseComponents[1]) else {
            throw MapperError.invalidVerseRef(ref)
        }

        return (book, chapter, verse)
    }

    /// verseRef나 locale에서 번역본 추출
    /// 한글 책명이면 "개역개정", 영어 책명이면 "NIV"로 기본 설정
    private static func extractTranslation(from ref: String) -> String {
        // 한글이 포함되어 있으면 개역개정
        let hasKorean = ref.range(of: "[ㄱ-ㅎㅏ-ㅣ가-힣]", options: .regularExpression) != nil
        return hasKorean ? "개역개정" : "NIV"
    }
}
