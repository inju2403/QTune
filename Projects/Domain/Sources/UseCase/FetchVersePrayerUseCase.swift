//
//  FetchVersePrayerUseCase.swift
//  Domain
//
//  Created by 이승주 on 3/2/26.
//

import Foundation

/// 구절 기도문 조회 UseCase
/// 직접 검색한 구절에 대해 GPT-4o-mini로 기도문 생성
public protocol FetchVersePrayerUseCase: Sendable {
    func execute(englishText: String, verseRef: String) async throws -> String
}

/// 구절 기도문 조회 UseCase 구현체
public final class FetchVersePrayerInteractor: FetchVersePrayerUseCase {
    private let aiRepository: AIRepository
    private let userProfileRepository: UserProfileRepository

    public init(aiRepository: AIRepository, userProfileRepository: UserProfileRepository) {
        self.aiRepository = aiRepository
        self.userProfileRepository = userProfileRepository
    }

    public func execute(englishText: String, verseRef: String) async throws -> String {
        let profile = try? await userProfileRepository.getProfile()
        do {
            return try await aiRepository.fetchPrayer(
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
                throw DomainError.network("기도문을 생성하지 못했습니다: \(error.localizedDescription)")
            }
        }
    }
}
