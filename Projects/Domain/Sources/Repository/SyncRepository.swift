//
//  SyncRepository.swift
//  Domain
//
//  Created by Claude Code on 10/8/25.
//

import Foundation

/// 동기화 저장소 인터페이스
///
/// 로컬-리모트 간 QT 데이터를 동기화합니다.
/// - 로그인 직후 또는 네트워크 복구 시 호출
/// - 충돌 해결 정책: 최신 updatedAt 우선
///
/// ## 동기화 시나리오
/// 1. 익명 사용자가 로컬에 QT 작성
/// 2. Apple Sign In으로 로그인
/// 3. mergeLocalIntoRemote: 로컬 → 서버 업로드
/// 4. pullRemoteUpdates: 서버 → 로컬 다운로드
///
/// ## 충돌 해결 정책
/// - 동일 id의 QT가 로컬/리모트에 모두 존재하는 경우
/// - updatedAt이 더 최신인 것을 우선
/// - 동일 시각이면 서버 우선
public protocol SyncRepository {
    /// 로컬 데이터를 리모트로 병합
    ///
    /// 로그인 직후, 로컬에 있는 QT들을 서버로 업로드합니다.
    ///
    /// - Parameter session: 인증된 UserSession (authenticated만 가능)
    /// - Throws: DomainError.unauthorized (익명 세션인 경우)
    func mergeLocalIntoRemote(session: UserSession) async throws

    /// 리모트 업데이트를 로컬로 가져오기
    ///
    /// 서버의 최신 QT들을 로컬로 다운로드합니다.
    ///
    /// - Parameter session: 인증된 UserSession (authenticated만 가능)
    /// - Throws: DomainError.unauthorized (익명 세션인 경우)
    func pullRemoteUpdates(session: UserSession) async throws
}
