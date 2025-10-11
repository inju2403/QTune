//
//  GetCurrentSessionUseCase.swift
//  Domain
//
//  Created by 이승주 on 10/8/25.
//

import Foundation

/// 현재 세션 조회 유스케이스
///
/// ## 역할
/// - 현재 인증 상태 조회 (익명/로그인)
/// - 앱 시작 시 호출하여 세션 복원
///
/// ## 사용 예시
/// ```swift
/// let session = try await getCurrentSession.execute()
/// switch session.status {
/// case .anonymous:
///     // 익명 사용자
/// case .authenticated:
///     // 로그인 사용자
/// }
/// ```
public protocol GetCurrentSessionUseCase {
    /// 현재 세션 조회
    ///
    /// - Returns: 현재 UserSession (항상 반환, 익명 또는 로그인)
    func execute() async throws -> UserSession
}

/// GetCurrentSessionUseCase 구현체
public final class GetCurrentSessionInteractor: GetCurrentSessionUseCase {
    private let authRepository: AuthRepository

    public init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }

    public func execute() async throws -> UserSession {
        return try await authRepository.currentSession()
    }
}
