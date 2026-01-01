//
//  ToggleFavoriteUseCase.swift
//  Domain
//
//  Created by 이승주 on 10/8/25.
//

import Foundation

/// 즐겨찾기 토글 유스케이스
///
/// ## 역할
/// - QT의 즐겨찾기 상태를 토글
/// - true → false, false → true
///
/// ## 사용 예시
/// ```swift
/// let newFavoriteState = try await toggleFavorite.execute(id: qtId, session: session)
/// if newFavoriteState {
///     // 즐겨찾기에 추가됨
/// } else {
///     // 즐겨찾기에서 제거됨
/// }
/// ```
public protocol ToggleFavoriteUseCase {
    /// 즐겨찾기 토글
    ///
    /// - Parameters:
    ///   - id: QT ID
    ///   - session: 현재 사용자 세션
    /// - Returns: 토글 후의 isFavorite 상태 (true/false)
    func execute(id: UUID, session: UserSession) async throws -> Bool
}

/// ToggleFavoriteUseCase 구현체
public final class ToggleFavoriteInteractor: ToggleFavoriteUseCase {
    private let qtRepository: QTRepository

    public init(qtRepository: QTRepository) {
        self.qtRepository = qtRepository
    }

    public func execute(id: UUID, session: UserSession) async throws -> Bool {
        return try await qtRepository.toggleFavorite(id: id, session: session)
    }
}
