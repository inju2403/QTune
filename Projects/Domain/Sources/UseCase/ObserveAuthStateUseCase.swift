//
//  ObserveAuthStateUseCase.swift
//  Domain
//
//  Created by 이승주 on 10/8/25.
//

import Foundation

/// 인증 상태 관찰 유스케이스
///
/// ## 역할
/// - 인증 상태 변화를 실시간으로 관찰
/// - 로그인/로그아웃 이벤트 감지
///
/// ## 사용 예시
/// ```swift
/// for await session in observeAuthState.execute() {
///     switch session.status {
///     case .anonymous:
///         // 로그아웃됨
///     case .authenticated:
///         // 로그인됨
///     }
/// }
/// ```
public protocol ObserveAuthStateUseCase {
    /// 인증 상태 관찰
    ///
    /// - Returns: UserSession 스트림 (AsyncStream)
    func execute() -> AsyncStream<UserSession>
}

/// ObserveAuthStateUseCase 구현체
public final class ObserveAuthStateInteractor: ObserveAuthStateUseCase {
    private let authRepository: AuthRepository

    public init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }

    public func execute() -> AsyncStream<UserSession> {
        return authRepository.observeAuthState()
    }
}
