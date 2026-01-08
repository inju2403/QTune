//
//  AIRepository.swift
//  Domain
//
//  Created by 이승주 on 10/11/25.
//

import Foundation

/// AI 기반 말씀 생성 요청
public struct AIGenerateVerseRequest {
    public let locale: String       // 예: "ko_KR", "en_US"
    public let mood: String         // 사용자의 감정/상황
    public let note: String?        // 추가 메모
    public let nickname: String?    // 사용자 닉네임
    public let gender: String?      // 사용자 성별

    public init(locale: String, mood: String, note: String?, nickname: String? = nil, gender: String? = nil) {
        self.locale = locale
        self.mood = mood
        self.note = note
        self.nickname = nickname
        self.gender = gender
    }
}

/// AI Repository 에러
public enum AIRepositoryError: Error {
    case contentBlocked(reason: String)
    case invalidResponse
    case apiKeyNotConfigured
    case bibleAPIFailed(reason: String)
    case koreanExplanationFailed(reason: String)
    case dailyLimitExceeded
}

/// AI 기반 말씀 생성 Repository
public protocol AIRepository {
    /// 사용자 입력을 기반으로 말씀 생성
    /// - Parameter request: 생성 요청 정보
    /// - Returns: 생성된 말씀
    /// - Throws: AIRepositoryError
    func generateVerse(_ request: AIGenerateVerseRequest) async throws -> GeneratedVerse
}
