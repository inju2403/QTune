//
//  AuthRepository.swift
//  Domain
//
//  Created by Claude Code on 10/8/25.
//

import Foundation

/// 인증 저장소 인터페이스
///
/// 사용자 인증 상태를 관리합니다.
/// - 로그아웃 기능 없음 (요구사항)
/// - anonymous → authenticated 전환만 가능
public protocol AuthRepository {
    /// 현재 세션 조회
    ///
    /// 앱 시작 시 또는 필요 시점에 현재 사용자 세션을 반환합니다.
    /// - anonymous: 디바이스 ID 기반 (로그인하지 않은 경우)
    /// - authenticated: Apple Sign In으로 인증된 경우
    ///
    /// - Returns: 현재 UserSession
    func currentSession() async throws -> UserSession

    /// Apple Sign In
    ///
    /// Apple ID Token으로 인증하고 사용자 세션을 생성합니다.
    ///
    /// - Parameter idToken: Apple Sign In ID Token
    /// - Returns: 인증된 UserSession
    /// - Throws: DomainError.unauthorized (인증 실패)
    func signInWithApple(idToken: String) async throws -> UserSession

    /// 인증 상태 변화 관찰
    ///
    /// 앱 전역에서 세션 변화를 구독할 수 있는 스트림을 반환합니다.
    /// - 최초 연결 시 현재 세션 emit
    /// - 이후 변화 발생 시마다 새 세션 emit
    ///
    /// - Returns: UserSession 변화 스트림
    func observeAuthState() -> AsyncStream<UserSession>
}
