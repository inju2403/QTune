//
//  OpenAIRemoteDataSource.swift
//  Data
//
//  Created by 이승주 on 10/11/25.
//

import Foundation

/// OpenAI Remote Data Source 에러
public enum OpenAIDataSourceError: Error {
    case emptyResponse
    case invalidJSON
    case apiKeyNotFound
    case dailyLimitExceeded
    case unknown
}

/// OpenAI Remote Data Source 프로토콜
public protocol OpenAIRemoteDataSource {
    func recommendVerse(_ request: GenerateVerseRequest) async throws -> VerseRecommendationDTO
    func generateKoreanExplanation(englishText: String, verseRef: String, mood: String, note: String?) async throws -> KoreanExplanationDTO
}
