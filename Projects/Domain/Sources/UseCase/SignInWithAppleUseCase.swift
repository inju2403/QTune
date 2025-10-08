//
//  SignInWithAppleUseCase.swift
//  Domain
//
//  Created by Claude Code on 10/8/25.
//

import Foundation

/// Apple Sign In 유스케이스
///
/// ## 역할
/// - Apple Sign In 수행
/// - 로그인 직후 자동으로 동기화 수행 (merge → pull)
///
/// ## 사용 예시
/// ```swift
/// // Presentation 레이어에서 Apple Sign In UI 호출 후 idToken 획득
/// let session = try await signInWithApple.execute(idToken: appleIdToken)
/// // 로그인 + 동기화 완료
/// // session.status == .authenticated(userId: "...")
/// ```
public protocol SignInWithAppleUseCase {
    /// Apple Sign In 실행
    ///
    /// - Parameter idToken: Apple Sign In ID Token (Presentation 레이어에서 획득)
    /// - Returns: 인증된 UserSession
    /// - Throws:
    ///   - DomainError.unauthorized (인증 실패)
    ///   - DomainError.network (네트워크 오류)
    func execute(idToken: String) async throws -> UserSession
}

/// SignInWithAppleUseCase 구현체
public final class SignInWithAppleInteractor: SignInWithAppleUseCase {
    private let authRepository: AuthRepository
    private let syncRepository: SyncRepository

    public init(authRepository: AuthRepository, syncRepository: SyncRepository) {
        self.authRepository = authRepository
        self.syncRepository = syncRepository
    }

    public func execute(idToken: String) async throws -> UserSession {
        // 1. Apple Sign In 수행
        let session = try await authRepository.signInWithApple(idToken: idToken)

        // 2. 로그인 직후 동기화 수행
        // 순서: 로컬 → 리모트 업로드 → 리모트 → 로컬 다운로드
        do {
            try await syncRepository.mergeLocalIntoRemote(session: session)
            try await syncRepository.pullRemoteUpdates(session: session)
        } catch {
            // 동기화 실패해도 로그인은 성공으로 처리
            // (다음에 다시 시도 가능)
            // TODO: 로그 기록 또는 사용자에게 알림
        }

        return session
    }
}
