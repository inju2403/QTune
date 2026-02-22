//
//  FetchVerseExplanationUseCase.swift
//  Domain
//
//  Created by 이승주 on 2/18/26.
//

import Foundation

/// 구절 해설 조회 UseCase
/// 직접 검색한 구절에 대해 GPT-4o-mini로 객관적 성경 해설 생성
public protocol FetchVerseExplanationUseCase: Sendable {
    func execute(englishText: String, verseRef: String) async throws -> String
}

/// 구절 해설 조회 UseCase 구현체
public final class FetchVerseExplanationInteractor: FetchVerseExplanationUseCase {
    private let aiRepository: AIRepository
    private let userProfileRepository: UserProfileRepository

    public init(aiRepository: AIRepository, userProfileRepository: UserProfileRepository) {
        self.aiRepository = aiRepository
        self.userProfileRepository = userProfileRepository
    }

    public func execute(englishText: String, verseRef: String) async throws -> String {
        let profile = try? await userProfileRepository.getProfile()
        do {
            return try await aiRepository.explainVerse(
                englishText: englishText,
                verseRef: verseRef,
                nickname: profile?.nickname,
                gender: profile?.gender.rawValue
            )
        } catch let error as AIRepositoryError {
            switch error {
            case .apiKeyNotConfigured:
                throw DomainError.configurationError("API 키가 설정되지 않았습니다")
            case .dailyLimitExceeded:
                throw DomainError.rateLimited
            default:
                throw DomainError.network("해설을 생성하지 못했습니다: \(error.localizedDescription)")
            }
        }
    }
}
