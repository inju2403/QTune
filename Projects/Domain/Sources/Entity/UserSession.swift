//
//  UserSession.swift
//  Domain
//
//  Created by 이승주 on 10/8/25.
//

import Foundation

/// 사용자 인증 상태를 나타내는 열거형
///
/// - anonymous: 익명 사용자 (디바이스 ID 기반)
/// - authenticated: 인증된 사용자 (Apple Sign In)
public enum AuthStatus: Equatable, Hashable {
    case anonymous(deviceId: String)
    case authenticated(userId: String)

    /// 현재 세션의 식별자 반환
    public var identifier: String {
        switch self {
        case .anonymous(let deviceId): return deviceId
        case .authenticated(let userId): return userId
        }
    }

    /// 인증 여부
    public var isAuthenticated: Bool {
        if case .authenticated = self { return true }
        return false
    }
}

/// 사용자 세션 엔티티
///
/// 앱 전역에서 현재 사용자의 인증 상태를 관리합니다.
/// - 로그아웃 기능은 없음 (요구사항)
/// - anonymous → authenticated 전환만 가능
public struct UserSession: Equatable, Hashable {
    public let status: AuthStatus
    public let createdAt: Date

    public init(status: AuthStatus, createdAt: Date = .now) {
        self.status = status
        self.createdAt = createdAt
    }

    /// 익명 세션 생성
    public static func anonymous(deviceId: String) -> UserSession {
        UserSession(status: .anonymous(deviceId: deviceId))
    }

    /// 인증된 세션 생성
    public static func authenticated(userId: String) -> UserSession {
        UserSession(status: .authenticated(userId: userId))
    }
}
