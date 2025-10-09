//
//  GenerateVerseUseCase.swift
//  Domain
//
//  Created by 이승주 on 7/26/25.
//

import Foundation

/// 말씀 생성 유스케이스
///
/// ClientPreFilterUseCase로 정규화된 텍스트를 받아서
/// Rate Limiting + Moderation + LLM 생성을 수행합니다.
///
/// ## 사용 예시
/// ```swift
/// let generateVerse = GenerateVerseInteractor(
///     verseRepository: verseRepo,
///     rateLimiterRepository: rateLimiterRepo,
///     moderationRepository: moderationRepo
/// )
/// let result = try await generateVerse.execute(
///     normalizedText: "오늘 힘든 하루였어요",
///     userId: "user123",
///     timeZone: .current
/// )
/// ```
public protocol GenerateVerseUseCase {
    /// 말씀 생성 실행
    ///
    /// - Parameters:
    ///   - normalizedText: ClientPreFilterUseCase에서 정규화된 텍스트
    ///   - userId: 사용자 ID (rate limiting용)
    ///   - timeZone: 사용자 타임존 (하루 1회 제한 계산용, 기본값: .current)
    /// - Returns: 생성된 말씀
    /// - Throws:
    ///   - DomainError.rateLimited: 요청 제한 초과 (하루 1회)
    ///   - DomainError.moderationBlocked: 부적절한 콘텐츠
    ///   - DomainError.network: 네트워크 오류
    func execute(normalizedText: String, userId: String, timeZone: TimeZone) async throws -> GeneratedVerse
}

/// 말씀 생성 유스케이스 구현체
///
/// ## 역할
/// 1. 요청 빈도 제한 (Rate Limiting) - 하루 1회 (사용자 타임존 기준)
/// 2. 서버 측 콘텐츠 검증 (Moderation)
/// 3. 말씀 생성 요청 (LLM API)
///
/// ## 의존성
/// - RateLimiterRepository: 하루 1회 제한 (00:00~23:59, 타임존 기준)
/// - ModerationRepository: 서버 측 콘텐츠 분석
/// - VerseRepository: LLM API 호출
public final class GenerateVerseInteractor: GenerateVerseUseCase {
    private let verseRepository: VerseRepository
    private let rateLimiterRepository: RateLimiterRepository
    private let moderationRepository: ModerationRepository

    public init(
        verseRepository: VerseRepository,
        rateLimiterRepository: RateLimiterRepository,
        moderationRepository: ModerationRepository
    ) {
        self.verseRepository = verseRepository
        self.rateLimiterRepository = rateLimiterRepository
        self.moderationRepository = moderationRepository
    }

    public func execute(normalizedText: String, userId: String, timeZone: TimeZone = .current) async throws -> GeneratedVerse {
        // MARK: - 1단계: Rate Limiting 체크 (하루 1회)

        let rateLimitKey = "generate_verse:\(userId)"
        let canProceed = try await rateLimiterRepository.checkDailyLimit(
            key: rateLimitKey,
            date: Date(),
            timeZone: timeZone
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
