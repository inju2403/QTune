//
//  FirebaseFunctionsAIDataSource.swift
//  Data
//
//  Created by 이승주 on 11/28/25.
//

import Foundation
import FirebaseFunctions

/// Firebase Functions 기반 AI Data Source
///
/// OpenAI API를 직접 호출하는 대신, Firebase Functions를 통해 프록시 방식으로 호출합니다.
/// OPENAI_API_KEY는 Firebase Functions 환경변수에서만 관리되며, iOS 앱은 알 필요가 없습니다.
public final class FirebaseFunctionsAIDataSource: OpenAIRemoteDataSource {
    private let functions: Functions

    public init(functions: Functions = Functions.functions()) {
        self.functions = functions
    }

    public func recommendVerse(_ request: GenerateVerseRequest) async throws -> VerseRecommendationDTO {
        print("🔥 [FirebaseFunctionsAIDataSource] Calling recommendVerse function")
        print("   Mood: \(request.mood)")
        print("   Note: \(request.note ?? "none")")

        // Firebase Functions 호출 데이터 준비
        let data: [String: Any] = [
            "locale": request.locale,
            "mood": request.mood,
            "note": request.note ?? ""
        ]

        do {
            // Firebase Functions 호출
            let callable = functions.httpsCallable("recommendVerse")
            let result = try await callable.call(data)

            print("✅ [FirebaseFunctionsAIDataSource] Function call successful")

            // 응답 파싱
            guard let resultData = result.data as? [String: Any] else {
                print("🔴 [FirebaseFunctionsAIDataSource] Invalid response format")
                throw OpenAIDataSourceError.invalidJSON
            }

            guard let verseRef = resultData["verseRef"] as? String,
                  let rationale = resultData["rationale"] as? String else {
                print("🔴 [FirebaseFunctionsAIDataSource] Missing required fields")
                throw OpenAIDataSourceError.invalidJSON
            }

            let dto = VerseRecommendationDTO(
                verseRef: verseRef,
                rationale: rationale
            )

            print("✅ [FirebaseFunctionsAIDataSource] Parsed VerseRecommendationDTO")
            print("   verseRef: \(dto.verseRef)")
            return dto

        } catch let error as NSError {
            print("🔴 [FirebaseFunctionsAIDataSource] Error: \(error.localizedDescription)")

            // Firebase Functions 에러 처리
            if error.domain == FunctionsErrorDomain {
                let code = FunctionsErrorCode(rawValue: error.code)
                switch code {
                case .unauthenticated:
                    throw OpenAIDataSourceError.apiKeyNotFound
                case .invalidArgument:
                    throw OpenAIDataSourceError.invalidJSON
                default:
                    throw error
                }
            }

            throw error
        }
    }

    public func generateKoreanExplanation(
        englishText: String,
        verseRef: String,
        mood: String,
        note: String?
    ) async throws -> KoreanExplanationDTO {
        print("🔥 [FirebaseFunctionsAIDataSource] Calling generateKoreanExplanation function")
        print("   VerseRef: \(verseRef)")
        print("   Mood: \(mood)")

        // Firebase Functions 호출 데이터 준비
        var data: [String: Any] = [
            "englishText": englishText,
            "verseRef": verseRef,
            "mood": mood
        ]

        if let note = note {
            data["note"] = note
        }

        do {
            // Firebase Functions 호출
            let callable = functions.httpsCallable("generateKoreanExplanation")
            let result = try await callable.call(data)

            print("✅ [FirebaseFunctionsAIDataSource] Function call successful")

            // 응답 파싱
            guard let resultData = result.data as? [String: Any] else {
                print("🔴 [FirebaseFunctionsAIDataSource] Invalid response format")
                throw OpenAIDataSourceError.invalidJSON
            }

            guard let korean = resultData["korean"] as? String,
                  let rationale = resultData["rationale"] as? String else {
                print("🔴 [FirebaseFunctionsAIDataSource] Missing required fields")
                throw OpenAIDataSourceError.invalidJSON
            }

            let dto = KoreanExplanationDTO(
                korean: korean,
                rationale: rationale
            )

            print("✅ [FirebaseFunctionsAIDataSource] Parsed KoreanExplanationDTO")
            print("   korean: \(dto.korean.prefix(100))...")
            return dto

        } catch let error as NSError {
            print("🔴 [FirebaseFunctionsAIDataSource] Error: \(error.localizedDescription)")

            // Firebase Functions 에러 처리
            if error.domain == FunctionsErrorDomain {
                let code = FunctionsErrorCode(rawValue: error.code)
                switch code {
                case .unauthenticated:
                    throw OpenAIDataSourceError.apiKeyNotFound
                case .invalidArgument:
                    throw OpenAIDataSourceError.invalidJSON
                default:
                    throw error
                }
            }

            throw error
        }
    }
}
