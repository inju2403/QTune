//
//  FirebaseFunctionsAIDataSource.swift
//  App
//
//  Created by 이승주 on 11/28/25.
//

import Foundation
import FirebaseFunctions
import FirebaseAuth
import Domain
import Data

/// Firebase Functions 기반 AI Data Source
///
/// OpenAI API를 직접 호출하는 대신, Firebase Functions를 통해 프록시 방식으로 호출합니다.
/// OPENAI_API_KEY는 Firebase Functions 환경변수에서만 관리되며, iOS 앱은 알 필요가 없습니다.
public final class FirebaseFunctionsAIDataSource: OpenAIRemoteDataSource {
    // Lazy 초기화: FirebaseApp.configure() 이후에 처음 접근할 때 생성
    private lazy var functions: Functions = Functions.functions()

    // Sandbox 환경 체크
    private var isSandboxEnvironment: Bool {
        // Bundle ID로 환경 구분
        let bundleId = Bundle.main.bundleIdentifier ?? ""
        return bundleId.contains(".sandbox")
    }

    public init() {
        // functions는 lazy이므로 여기서는 생성하지 않음
    }

    public func recommendVerse(_ request: GenerateVerseRequest) async throws -> VerseRecommendationDTO {
        guard let currentUser = Auth.auth().currentUser else {
            print("🔴 [FirebaseFunctionsAIDataSource] User not authenticated")
            throw OpenAIDataSourceError.apiKeyNotFound
        }

        print("🔥 [FirebaseFunctionsAIDataSource] Calling recommendVerse function")
        print("   Mood: \(request.mood)")
        print("   Note: \(request.note ?? "none")")
        print("   UID: \(currentUser.uid)")
        print("   IsAnonymous: \(currentUser.isAnonymous)")

        // Firebase Functions 호출 데이터 준비
        var data: [String: Any] = [
            "locale": request.locale,
            "mood": request.mood,
            "note": request.note ?? "",
            "isSandbox": isSandboxEnvironment  // 환경 정보 추가
        ]

        // 프로필 정보 추가
        if let nickname = request.nickname {
            data["nickname"] = nickname
        }
        if let gender = request.gender {
            data["gender"] = gender
        }

        // 디버깅용 로그
        if isSandboxEnvironment {
            print("🏖️ [FirebaseFunctionsAIDataSource] Running in SANDBOX environment")
        }

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
            print("🔴 [FirebaseFunctionsAIDataSource] Error occurred")
            print("   Domain: \(error.domain)")
            print("   Code: \(error.code)")
            print("   Description: \(error.localizedDescription)")
            print("   UserInfo: \(error.userInfo)")

            // Firebase Functions 에러 처리
            if error.domain == FunctionsErrorDomain {
                let code = FunctionsErrorCode(rawValue: error.code)
                print("   FunctionsErrorCode: \(code?.rawValue ?? -1)")

                // 상세 메시지 추출
                if let message = error.userInfo["NSLocalizedDescription"] as? String {
                    print("   Message: \(message)")
                }
                if let details = error.userInfo["details"] as? [String: Any] {
                    print("   Details: \(details)")
                }

                switch code {
                case .unauthenticated:
                    throw OpenAIDataSourceError.apiKeyNotFound
                case .invalidArgument:
                    throw OpenAIDataSourceError.invalidJSON
                case .resourceExhausted:
                    throw OpenAIDataSourceError.dailyLimitExceeded
                default:
                    throw OpenAIDataSourceError.unknown
                }
            }

            throw OpenAIDataSourceError.unknown
        }
    }

    public func generateKoreanExplanation(
        englishText: String,
        verseRef: String,
        mood: String,
        note: String?,
        nickname: String?,
        gender: String?
    ) async throws -> KoreanExplanationDTO {
        guard let currentUser = Auth.auth().currentUser else {
            print("🔴 [FirebaseFunctionsAIDataSource] User not authenticated")
            throw OpenAIDataSourceError.apiKeyNotFound
        }

        print("🔥 [FirebaseFunctionsAIDataSource] Calling generateKoreanExplanation function")
        print("   VerseRef: \(verseRef)")
        print("   Mood: \(mood)")
        print("   UID: \(currentUser.uid)")
        print("   IsAnonymous: \(currentUser.isAnonymous)")

        // Firebase Functions 호출 데이터 준비
        var data: [String: Any] = [
            "englishText": englishText,
            "verseRef": verseRef,
            "mood": mood,
            "isSandbox": isSandboxEnvironment  // 환경 정보 추가
        ]

        if let note = note {
            data["note"] = note
        }

        // 프로필 정보 추가
        if let nickname = nickname {
            data["nickname"] = nickname
        }
        if let gender = gender {
            data["gender"] = gender
        }

        // 디버깅용 로그
        if isSandboxEnvironment {
            print("🏖️ [FirebaseFunctionsAIDataSource] Running in SANDBOX environment")
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
            print("🔴 [FirebaseFunctionsAIDataSource] Error occurred")
            print("   Domain: \(error.domain)")
            print("   Code: \(error.code)")
            print("   Description: \(error.localizedDescription)")
            print("   UserInfo: \(error.userInfo)")

            // Firebase Functions 에러 처리
            if error.domain == FunctionsErrorDomain {
                let code = FunctionsErrorCode(rawValue: error.code)
                print("   FunctionsErrorCode: \(code?.rawValue ?? -1)")

                // 상세 메시지 추출
                if let message = error.userInfo["NSLocalizedDescription"] as? String {
                    print("   Message: \(message)")
                }
                if let details = error.userInfo["details"] as? [String: Any] {
                    print("   Details: \(details)")
                }

                switch code {
                case .unauthenticated:
                    throw OpenAIDataSourceError.apiKeyNotFound
                case .invalidArgument:
                    throw OpenAIDataSourceError.invalidJSON
                case .resourceExhausted:
                    throw OpenAIDataSourceError.dailyLimitExceeded
                default:
                    throw OpenAIDataSourceError.unknown
                }
            }

            throw OpenAIDataSourceError.unknown
        }
    }

    public func getVerseExplanation(englishText: String, verseRef: String) async throws -> String {
        guard let currentUser = Auth.auth().currentUser else {
            print("🔴 [FirebaseFunctionsAIDataSource] User not authenticated")
            throw OpenAIDataSourceError.apiKeyNotFound
        }

        print("🔥 [FirebaseFunctionsAIDataSource] Calling getVerseExplanation function")
        print("   VerseRef: \(verseRef)")
        print("   UID: \(currentUser.uid)")

        let data: [String: Any] = [
            "englishText": englishText,
            "verseRef": verseRef,
            "isSandbox": isSandboxEnvironment
        ]

        if isSandboxEnvironment {
            print("🏖️ [FirebaseFunctionsAIDataSource] Running in SANDBOX environment")
        }

        do {
            let callable = functions.httpsCallable("getVerseExplanation")
            let result = try await callable.call(data)

            print("✅ [FirebaseFunctionsAIDataSource] getVerseExplanation successful")

            guard let resultData = result.data as? [String: Any],
                  let explanation = resultData["explanation"] as? String else {
                print("🔴 [FirebaseFunctionsAIDataSource] Invalid response format")
                throw OpenAIDataSourceError.invalidJSON
            }

            print("✅ [FirebaseFunctionsAIDataSource] Explanation: \(explanation.prefix(80))...")
            return explanation

        } catch let error as NSError {
            print("🔴 [FirebaseFunctionsAIDataSource] getVerseExplanation error")
            print("   Domain: \(error.domain)")
            print("   Code: \(error.code)")
            print("   Description: \(error.localizedDescription)")

            if error.domain == FunctionsErrorDomain {
                let code = FunctionsErrorCode(rawValue: error.code)
                switch code {
                case .unauthenticated:
                    throw OpenAIDataSourceError.apiKeyNotFound
                case .invalidArgument:
                    throw OpenAIDataSourceError.invalidJSON
                case .resourceExhausted:
                    throw OpenAIDataSourceError.dailyLimitExceeded
                default:
                    throw OpenAIDataSourceError.unknown
                }
            }

            throw OpenAIDataSourceError.unknown
        }
    }
}