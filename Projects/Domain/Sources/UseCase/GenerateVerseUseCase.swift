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
/// 1. 입력 검증 (InputValidator)
/// 2. 요청 빈도 제한 (Rate Limiting) - 하루 1회 (사용자 타임존 기준)
/// 3. 말씀 생성 요청 (AI API)
///
/// ## 의존성
/// - RateLimiterRepository: 하루 1회 제한 (00:00~23:59, 타임존 기준)
/// - AIRepository: OpenAI API 호출 (내부적으로 safety 검증 포함)
///
/// ## 주의
/// - Moderation은 OpenAI API 내부에서 safety 필드로 검증됨
/// - 기존 ModerationRepository는 deprecated 예정
public final class GenerateVerseInteractor: GenerateVerseUseCase {
    private let aiRepository: AIRepository
    private let rateLimiterRepository: RateLimiterRepository

    public init(
        aiRepository: AIRepository,
        rateLimiterRepository: RateLimiterRepository
    ) {
        self.aiRepository = aiRepository
        self.rateLimiterRepository = rateLimiterRepository
    }

    public func execute(normalizedText: String, userId: String, timeZone: TimeZone = .current) async throws -> GeneratedVerse {
        // MARK: - 1단계: 입력 검증

        do {
            try InputValidator.validate(mood: normalizedText, note: nil)
        } catch let error as InputValidationError {
            switch error {
            case .tooLong(let maxLength):
                throw DomainError.validationFailed("입력이 너무 깁니다. (최대 \(maxLength)자)")
            case .tooShort(let minLength):
                throw DomainError.validationFailed("입력이 너무 짧습니다. (최소 \(minLength)자)")
            case .containsSpam:
                throw DomainError.validationFailed("스팸으로 의심되는 내용이 포함되어 있습니다.")
            case .containsForbiddenContent:
                throw DomainError.validationFailed("부적절한 내용이 포함되어 있습니다.")
            }
        }

        // MARK: - 2단계: Rate Limiting 체크 (하루 1회)

        // TODO: - 배포 시 주석 해제 (테스트 시에는 주석 처리)
        /*
        let rateLimitKey = "generate_verse:\(userId)"
        print("📊 [GenerateVerseUseCase] Checking rate limit for user: \(userId)")
        print("   Key: \(rateLimitKey)")

        let canProceed = try await rateLimiterRepository.checkDailyLimit(
            key: rateLimitKey,
            date: Date(),
            timeZone: timeZone
        )

        print("   Result: \(canProceed ? "ALLOWED ✅" : "BLOCKED ❌")")

        guard canProceed else {
            print("   Throwing DomainError.rateLimited")
            throw DomainError.rateLimited
        }
        */

        // MARK: - 3단계: 말씀 생성 (AI API 호출)
        // OpenAI API는 내부적으로 safety 검증을 수행하고,
        // blocked인 경우 AIRepositoryError.contentBlocked를 throw함

        let request = AIGenerateVerseRequest(
            locale: Locale.current.identifier,
            mood: normalizedText,
            note: nil
        )

        do {
            return try await aiRepository.generateVerse(request)
        } catch let error as AIRepositoryError {
            switch error {
            case .contentBlocked(let reason):
                throw DomainError.moderationBlocked(reason)
            case .invalidResponse:
                throw DomainError.network("응답 형식이 올바르지 않습니다")
            case .apiKeyNotConfigured:
                throw DomainError.configurationError("API 키가 설정되지 않았습니다")
            case .bibleAPIFailed(let reason):
                throw DomainError.network("본문을 불러오지 못했습니다: \(reason)")
            case .koreanExplanationFailed(let reason):
                throw DomainError.network("해설을 생성하지 못했습니다: \(reason)")
            }
        }
    }
}
