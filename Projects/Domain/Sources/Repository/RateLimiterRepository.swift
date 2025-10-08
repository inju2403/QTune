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
/// // 말씀 생성: 시간당 10회
/// let canProceed = try await rateLimiter.checkAndConsume(
///     key: "generate_verse:\(userId)",
///     max: 10,
///     per: .hour
/// )
/// if !canProceed {
///     throw DomainError.rateLimited
/// }
/// ```
public protocol RateLimiterRepository {
    /// 요청 가능 여부 확인 및 차감
    ///
    /// - Parameters:
    ///   - key: 제한 키 (예: "generate_verse:user123")
    ///   - max: 최대 허용 횟수
    ///   - per: 기간 (초 단위)
    /// - Returns: 요청 가능 여부 (true: 가능, false: 제한 초과)
    func checkAndConsume(key: String, max: Int, per: TimeInterval) async throws -> Bool
}
