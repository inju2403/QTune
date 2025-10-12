//
//  DeleteQTUseCase.swift
//  Domain
//
//  Created by 이승주 on 10/12/25.
//

import Foundation

/// QT 삭제 유스케이스
public protocol DeleteQTUseCase {
    /// QT 삭제
    ///
    /// - Parameters:
    ///   - id: 삭제할 QT ID
    ///   - session: 현재 사용자 세션
    func execute(id: UUID, session: UserSession) async throws
}

/// DeleteQTUseCase 구현체
public final class DeleteQTInteractor: DeleteQTUseCase {
    private let qtRepository: QTRepository

    public init(qtRepository: QTRepository) {
        self.qtRepository = qtRepository
    }

    public func execute(id: UUID, session: UserSession) async throws {
        try await qtRepository.delete(id: id, session: session)
    }
}
