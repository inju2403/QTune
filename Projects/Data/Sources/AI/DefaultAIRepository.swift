//
//  DefaultAIRepository.swift
//  Data
//
//  Created by 이승주 on 10/11/25.
//

import Foundation
import Domain

/// AI Repository 기본 구현체
public final class DefaultAIRepository: AIRepository {
    private let bibleDataSource: BibleAPIDataSource
    private let openAIDataSource: OpenAIRemoteDataSource

    public init(
        bibleDataSource: BibleAPIDataSource,
        openAIDataSource: OpenAIRemoteDataSource
    ) {
        self.bibleDataSource = bibleDataSource
        self.openAIDataSource = openAIDataSource
    }

    public func generateVerse(_ request: AIGenerateVerseRequest) async throws -> GeneratedVerse {
        print("🔄 [DefaultAIRepository] Starting verse generation pipeline")

        // Domain 요청을 Data 요청으로 변환
        let dataRequest = GenerateVerseRequest(
            locale: request.locale,
            mood: request.mood,
            note: request.note
        )

        // 1. OpenAI에서 구절 추천받기
        print("🤖 [DefaultAIRepository] Recommending verse from OpenAI...")
        let recommendation: VerseRecommendationDTO
        do {
            recommendation = try await openAIDataSource.recommendVerse(dataRequest)
            print("✅ [DefaultAIRepository] Verse recommended: \(recommendation.verseRef)")
        } catch {
            print("🔴 [DefaultAIRepository] Verse recommendation failed: \(error)")
            throw AIRepositoryError.koreanExplanationFailed(reason: error.localizedDescription)
        }

        // 2. Bible API에서 영어 본문 가져오기 (WEB → KJV 폴백)
        print("📖 [DefaultAIRepository] Fetching English text from Bible API...")
        let bibleDTO: BibleVerseDTO
        do {
            bibleDTO = try await bibleDataSource.getVerse(verseRef: recommendation.verseRef)
            print("✅ [DefaultAIRepository] English text fetched: \(bibleDTO.translation_id ?? "unknown")")
        } catch {
            print("🔴 [DefaultAIRepository] Bible API failed: \(error)")
            throw AIRepositoryError.bibleAPIFailed(reason: error.localizedDescription)
        }

        // 3. OpenAI에서 한글 해설 생성
        print("🤖 [DefaultAIRepository] Generating Korean explanation...")
        let koreanExplanation: KoreanExplanationDTO
        do {
            koreanExplanation = try await openAIDataSource.generateKoreanExplanation(
                englishText: bibleDTO.text,
                verseRef: recommendation.verseRef,
                mood: request.mood,
                note: request.note
            )
            print("✅ [DefaultAIRepository] Korean explanation generated")
        } catch {
            print("🔴 [DefaultAIRepository] Korean explanation failed: \(error)")
            throw AIRepositoryError.koreanExplanationFailed(reason: error.localizedDescription)
        }

        // 4. Domain 모델로 변환
        let verse = try parseVerse(
            reference: bibleDTO.reference,
            text: bibleDTO.text,
            translation: bibleDTO.translation_id ?? "WEB"
        )

        let generatedVerse = GeneratedVerse(
            verse: verse,
            korean: koreanExplanation.korean,
            reason: koreanExplanation.rationale
        )

        print("✅ [DefaultAIRepository] Pipeline completed successfully")
        return generatedVerse
    }

    // MARK: - Private Methods

    /// verseRef를 파싱하여 Verse 모델로 변환
    /// - Parameters:
    ///   - reference: "John 3:16" 형식의 참조
    ///   - text: 본문 텍스트
    ///   - translation: 번역본 ID
    /// - Returns: Verse 모델
    private func parseVerse(reference: String, text: String, translation: String) throws -> Verse {
        // "John 3:16" 형식 파싱
        let components = reference.split(separator: " ")
        guard components.count >= 2 else {
            throw AIRepositoryError.invalidResponse
        }

        let book = components[0..<components.count-1].joined(separator: " ")
        let chapterVerse = String(components.last!)

        let chapterVerseComponents = chapterVerse.split(separator: ":")
        guard chapterVerseComponents.count == 2,
              let chapter = Int(chapterVerseComponents[0]),
              let verse = Int(chapterVerseComponents[1]) else {
            throw AIRepositoryError.invalidResponse
        }

        return Verse(
            book: book,
            chapter: chapter,
            verse: verse,
            text: text,
            translation: translation
        )
    }
}
