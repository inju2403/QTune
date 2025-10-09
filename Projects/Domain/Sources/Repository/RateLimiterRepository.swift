//
//  RateLimiterRepository.swift
//  Domain
//
//  Created by Claude Code on 10/8/25.
//

import Foundation

/// 요청 횟수 제한 저장소 인터페이스
///
/// 사용자별 API 요청 빈도를 제한합니다.
/// - 클라이언트: UX 개선용 (미리 체크해서 사용자에게 안내)
/// - 서버: 보안/정책 강제 (실제 차단)
///
/// ## 사용 예시
/// ```swift
/// // 말씀 생성: 하루 1회 (사용자 타임존 기준)
/// let canProceed = try await rateLimiter.checkDailyLimit(
///     key: "generate_verse:\(userId)",
///     date: Date(),
///     timeZone: .current
/// )
/// if !canProceed {
///     throw DomainError.rateLimited
/// }
/// ```
public protocol RateLimiterRepository {
    /// 시간 기반 요청 제한 (시간당/분당)
    ///
    /// - Parameters:
    ///   - key: 제한 키 (예: "api_call:user123")
    ///   - max: 최대 허용 횟수
    ///   - per: 기간 (초 단위)
    /// - Returns: 요청 가능 여부 (true: 가능, false: 제한 초과)
    func checkAndConsume(key: String, max: Int, per: TimeInterval) async throws -> Bool

    /// 하루 1회 제한 (사용자 타임존 기준 00:00~23:59)
    ///
    /// - Parameters:
    ///   - key: 제한 키 (예: "generate_verse:user123")
    ///   - date: 현재 시간
    ///   - timeZone: 사용자 타임존
    /// - Returns: 요청 가능 여부 (true: 가능, false: 오늘 이미 사용)
    func checkDailyLimit(key: String, date: Date, timeZone: TimeZone) async throws -> Bool
}
