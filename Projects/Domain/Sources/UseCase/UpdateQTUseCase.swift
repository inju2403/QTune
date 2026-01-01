//
//  UpdateQTUseCase.swift
//  Domain
//
//  Created by 이승주 on 10/12/25.
//

import Foundation

/// QT 업데이트 유스케이스
public protocol UpdateQTUseCase {
    /// QT 전체 업데이트 (템플릿 필드 포함)
    ///
    /// - Parameters:
    ///   - qt: 업데이트할 QuietTime
    ///   - session: 현재 사용자 세션
    /// - Returns: 업데이트된 QuietTime
    func execute(qt: QuietTime, session: UserSession) async throws -> QuietTime
}

/// UpdateQTUseCase 구현체
public final class UpdateQTInteractor: UpdateQTUseCase {
    private let qtRepository: QTRepository

    public init(qtRepository: QTRepository) {
        self.qtRepository = qtRepository
    }

    public func execute(qt: QuietTime, session: UserSession) async throws -> QuietTime {
        return try await qtRepository.update(qt, session: session)
    }
}
