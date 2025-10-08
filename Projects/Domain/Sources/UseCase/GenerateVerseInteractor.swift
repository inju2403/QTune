//
//  GenerateVerseInteractor.swift
//  Domain
//
//  Created by 이승주 on 7/26/25.
//

import Foundation

/// 말씀 생성 유스케이스 구현체
///
/// ## 역할
/// 1. 요청 빈도 제한 (Rate Limiting)
/// 2. 서버 측 콘텐츠 검증 (Moderation)
/// 3. 말씀 생성 요청 (LLM API)
///
/// ## 의존성
/// - RateLimiterRepository: 시간당 요청 횟수 제한
/// - ModerationRepository: 서버 측 콘텐츠 분석
/// - VerseRepository: LLM API 호출
///
/// ## 사용 예시
/// ```swift
/// let result = try await generateVerseUseCase.execute(
///     normalizedText: "오늘 힘든 하루였어요",
///     userId: "user123"
/// )
/// ```
///
/// ## 에러 처리
/// - DomainError.rateLimited: 시간당 요청 제한 초과
/// - DomainError.moderationBlocked: 부적절한 콘텐츠 감지
/// - DomainError.network: 네트워크 오류
public final class GenerateVerseInteractor: GenerateVerseUseCase {
    private let verseRepository: VerseRepository
    private let rateLimiterRepository: RateLimiterRepository
    private let moderationRepository: ModerationRepository

    /// 시간당 최대 요청 횟수
    private let maxRequestsPerHour: Int

    public init(
        verseRepository: VerseRepository,
        rateLimiterRepository: RateLimiterRepository,
        moderationRepository: ModerationRepository,
        maxRequestsPerHour: Int = 10
    ) {
        self.verseRepository = verseRepository
        self.rateLimiterRepository = rateLimiterRepository
        self.moderationRepository = moderationRepository
        self.maxRequestsPerHour = maxRequestsPerHour
    }

    /// 말씀 생성 실행
    ///
    /// - Parameters:
    ///   - normalizedText: ClientPreFilterUseCase에서 정규화된 텍스트
    ///   - userId: 사용자 ID (rate limiting용)
    /// - Returns: 생성된 말씀
    /// - Throws:
    ///   - DomainError.rateLimited: 요청 제한 초과
    ///   - DomainError.moderationBlocked: 부적절한 콘텐츠
    ///   - DomainError.network: 네트워크 오류
    public func execute(normalizedText: String, userId: String) async throws -> GeneratedVerse {
        // MARK: - 1단계: Rate Limiting 체크

        let rateLimitKey = "generate_verse:\(userId)"
        let canProceed = try await rateLimiterRepository.checkAndConsume(
            key: rateLimitKey,
            max: maxRequestsPerHour,
            per: 3600 // 1시간 = 3600초
        )

        guard canProceed else {
            throw DomainError.rateLimited
        }

        // MARK: - 2단계: 서버 측 Moderation 검증

        let moderationReport = try await moderationRepository.analyze(text: normalizedText)

        switch moderationReport.verdict {
        case .blocked(let reason):
            throw DomainError.moderationBlocked(reason)

        case .needsReview(let reason):
            // needsReview: 경고하지만 진행 허용
            // 서버가 safe mode prompt로 생성 진행
            // UI에서는 별도 처리 없음 (서버가 알아서 안전 모드 적용)
            break

        case .allowed:
            // 정상 진행
            break
        }

        // MARK: - 3단계: 말씀 생성 (LLM API 호출)

        return try await verseRepository.generate(prompt: normalizedText)
    }
}
