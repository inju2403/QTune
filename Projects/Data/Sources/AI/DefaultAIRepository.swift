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
            note: request.note,
            nickname: request.nickname,
            gender: request.gender
        )

        // 1. OpenAI에서 구절 추천받기
        print("🤖 [DefaultAIRepository] Recommending verse from OpenAI...")
        let recommendation: VerseRecommendationDTO
        do {
            recommendation = try await openAIDataSource.recommendVerse(dataRequest)
            print("✅ [DefaultAIRepository] Verse recommended: \(recommendation.verseRef)")
        } catch let error as OpenAIDataSourceError {
            print("🔴 [DefaultAIRepository] Verse recommendation failed: \(error)")
            switch error {
            case .dailyLimitExceeded:
                throw AIRepositoryError.dailyLimitExceeded
            case .apiKeyNotFound:
                throw AIRepositoryError.apiKeyNotConfigured
            default:
                throw AIRepositoryError.koreanExplanationFailed(reason: error.localizedDescription)
            }
        } catch {
            print("🔴 [DefaultAIRepository] Verse recommendation failed: \(error)")
            throw AIRepositoryError.koreanExplanationFailed(reason: error.localizedDescription)
        }

        // 2. Bible API에서 주 역본 본문 가져오기
        print("📖 [DefaultAIRepository] Fetching primary translation: \(request.primaryTranslation.displayName)")
        let bibleDTO: BibleVerseDTO
        do {
            bibleDTO = try await bibleDataSource.getVerseWithTranslation(
                verseRef: recommendation.verseRef,
                translation: request.primaryTranslation.code
            )
            print("✅ [DefaultAIRepository] Primary text fetched: \(bibleDTO.translation_id ?? "unknown")")
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
                note: request.note,
                nickname: request.nickname,
                gender: request.gender
            )
            print("✅ [DefaultAIRepository] Korean explanation generated")
        } catch let error as OpenAIDataSourceError {
            print("🔴 [DefaultAIRepository] Korean explanation failed: \(error)")
            switch error {
            case .dailyLimitExceeded:
                throw AIRepositoryError.dailyLimitExceeded
            case .apiKeyNotFound:
                throw AIRepositoryError.apiKeyNotConfigured
            default:
                throw AIRepositoryError.koreanExplanationFailed(reason: error.localizedDescription)
            }
        } catch {
            print("🔴 [DefaultAIRepository] Korean explanation failed: \(error)")
            throw AIRepositoryError.koreanExplanationFailed(reason: error.localizedDescription)
        }

        // 4. 비교 역본 가져오기 (선택사항)
        var secondaryVerse: Verse? = nil
        if let secondaryTranslation = request.secondaryTranslation {
            print("📖 [DefaultAIRepository] Fetching secondary translation: \(secondaryTranslation.displayName)")

            do {
                let secondaryDTO = try await bibleDataSource.getVerseWithTranslation(
                    verseRef: recommendation.verseRef,
                    translation: secondaryTranslation.code
                )
                secondaryVerse = try parseVerse(
                    reference: secondaryDTO.reference,
                    text: secondaryDTO.text,
                    translation: secondaryDTO.translation_id ?? secondaryTranslation.code
                )
                print("✅ [DefaultAIRepository] Secondary verse fetched: \(secondaryTranslation.displayName)")
            } catch {
                print("⚠️ [DefaultAIRepository] Secondary translation fetch failed: \(error)")
                // 비교 역본 실패는 무시하고 계속 진행
            }
        }

        // 5. Domain 모델로 변환
        let verse = try parseVerse(
            reference: bibleDTO.reference,
            text: bibleDTO.text,
            translation: bibleDTO.translation_id ?? "WEB"
        )

        let generatedVerse = GeneratedVerse(
            verse: verse,
            secondaryVerse: secondaryVerse,
            korean: koreanExplanation.korean,
            reason: koreanExplanation.rationale
        )

        print("✅ [DefaultAIRepository] Pipeline completed successfully")

        // 6. Firestore에 말씀 추천 기록 저장 (푸시 알림용)
        await recordVerseRequest()

        return generatedVerse
    }

    public func explainVerse(englishText: String, verseRef: String) async throws -> String {
        print("🔄 [DefaultAIRepository] Fetching verse explanation for \(verseRef)")

        do {
            let explanation = try await openAIDataSource.getVerseExplanation(
                englishText: englishText,
                verseRef: verseRef
            )
            print("✅ [DefaultAIRepository] Verse explanation fetched")
            return explanation
        } catch let error as OpenAIDataSourceError {
            print("🔴 [DefaultAIRepository] Verse explanation failed: \(error)")
            switch error {
            case .dailyLimitExceeded:
                throw AIRepositoryError.dailyLimitExceeded
            case .apiKeyNotFound:
                throw AIRepositoryError.apiKeyNotConfigured
            default:
                throw AIRepositoryError.koreanExplanationFailed(reason: error.localizedDescription)
            }
        } catch {
            print("🔴 [DefaultAIRepository] Verse explanation failed: \(error)")
            throw AIRepositoryError.koreanExplanationFailed(reason: error.localizedDescription)
        }
    }

    // MARK: - Private Methods

    /// verseRef를 파싱하여 Verse 모델로 변환
    /// - Parameters:
    ///   - reference: "John 3:16" 또는 "Philippians 4:6-7" 형식의 참조
    ///   - text: 본문 텍스트
    ///   - translation: 번역본 ID
    /// - Returns: Verse 모델
    private func parseVerse(reference: String, text: String, translation: String) throws -> Verse {
        // "John 3:16" 또는 "Philippians 4:6-7" 형식 파싱
        let components = reference.split(separator: " ")
        guard components.count >= 2 else {
            throw AIRepositoryError.invalidResponse
        }

        let book = components[0..<components.count-1].joined(separator: " ")
        let chapterVerse = String(components.last!)

        let chapterVerseComponents = chapterVerse.split(separator: ":")
        guard chapterVerseComponents.count == 2,
              let chapter = Int(chapterVerseComponents[0]) else {
            throw AIRepositoryError.invalidResponse
        }

        // 절 번호 파싱 (단일 또는 범위)
        // 예: "5-6" → startVerse=5, endVerse=6 / "16" → startVerse=16, endVerse=nil
        let verseString = String(chapterVerseComponents[1])
        let startVerseNumber: Int
        let endVerseNumber: Int?
        if let dashIndex = verseString.firstIndex(of: "-") {
            let startStr = String(verseString[..<dashIndex])
            let endStr = String(verseString[verseString.index(after: dashIndex)...])
            guard let start = Int(startStr), let end = Int(endStr) else {
                throw AIRepositoryError.invalidResponse
            }
            startVerseNumber = start
            endVerseNumber = end
        } else {
            guard let verse = Int(verseString) else {
                throw AIRepositoryError.invalidResponse
            }
            startVerseNumber = verse
            endVerseNumber = nil
        }

        return Verse(
            book: book,
            chapter: chapter,
            verse: startVerseNumber,
            endVerse: endVerseNumber,
            text: text,
            translation: translation
        )
    }

    /// Firestore에 말씀 추천 요청 기록 (푸시 알림 타겟팅용)
    private func recordVerseRequest() async {
        // Cloud Functions가 이미 uid를 기록하므로 iOS에서는 스킵
        // 말씀 추천 요청은 OpenAI API 호출 시 Cloud Functions에서 자동으로 기록됨
        // TODO: 필요시 UseCase 레벨에서 uid를 전달받아 기록
    }
}
