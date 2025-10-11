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
    private let remoteDataSource: OpenAIRemoteDataSource

    public init(remoteDataSource: OpenAIRemoteDataSource) {
        self.remoteDataSource = remoteDataSource
    }

    public func generateVerse(_ request: AIGenerateVerseRequest) async throws -> GeneratedVerse {
        // 1. Domain 요청을 Data 요청으로 변환
        let dataRequest = GenerateVerseRequest(
            locale: request.locale,
            mood: request.mood,
            note: request.note
        )

        // 2. Remote Data Source 호출
        let dto = try await remoteDataSource.generate(dataRequest)

        // 3. 안전성 검증 (정책)
        guard dto.safety.status == "ok" else {
            throw AIRepositoryError.contentBlocked(reason: dto.safety.reason)
        }

        // 4. DTO를 Domain 모델로 변환
        let generatedVerse = try OpenAIMapper.toDomain(dto)

        return generatedVerse
    }
}
