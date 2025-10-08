//
//  DomainError.swift
//  Domain
//
//  Created by Claude Code on 10/8/25.
//

import Foundation

/// 도메인 레이어 통합 에러
///
/// 모든 도메인 로직에서 발생하는 에러를 일관된 타입으로 표현합니다.
/// - validationFailed: 입력 검증 실패
/// - moderationBlocked: 콘텐츠 모더레이션으로 차단됨
/// - unauthorized: 인증 필요
/// - notFound: 리소스 없음
/// - rateLimited: 요청 횟수 제한 초과
/// - network: 네트워크 관련 오류
/// - unknown: 알 수 없는 오류
public enum DomainError: Error, Equatable {
    case validationFailed(String)
    case moderationBlocked(String)
    case unauthorized
    case notFound
    case rateLimited
    case network(String)
    case unknown

    /// 사용자에게 표시할 메시지
    public var userMessage: String {
        switch self {
        case .validationFailed(let message):
            return message
        case .moderationBlocked(let reason):
            return "입력하신 내용이 검토가 필요합니다: \(reason)"
        case .unauthorized:
            return "로그인이 필요합니다"
        case .notFound:
            return "요청하신 항목을 찾을 수 없습니다"
        case .rateLimited:
            return "요청이 너무 많습니다. 잠시 후 다시 시도해주세요"
        case .network(let message):
            return "네트워크 오류: \(message)"
        case .unknown:
            return "알 수 없는 오류가 발생했습니다"
        }
    }

    /// 재시도 가능 여부
    public var isRetryable: Bool {
        switch self {
        case .rateLimited, .network:
            return true
        default:
            return false
        }
    }
}
