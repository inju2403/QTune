//
//  GetQTDetailUseCase.swift
//  Domain
//
//  Created by Claude Code on 10/8/25.
//

import Foundation

/// QT 상세 조회 유스케이스
///
/// ## 역할
/// - ID로 단건 QT 조회
/// - 상세 화면에서 사용
///
/// ## 사용 예시
/// ```swift
/// let qt = try await getQTDetail.execute(id: qtId, session: session)
/// // QT가 없으면 DomainError.notFound
/// ```
public protocol GetQTDetailUseCase {
    /// QT 상세 조회
    ///
    /// - Parameters:
    ///   - id: QT ID
    ///   - session: 현재 사용자 세션
    /// - Returns: QuietTime
    /// - Throws: DomainError.notFound (QT가 없거나 다른 사용자의 QT인 경우)
    func execute(id: UUID, session: UserSession) async throws -> QuietTime
}

/// GetQTDetailUseCase 구현체
public final class GetQTDetailInteractor: GetQTDetailUseCase {
    private let qtRepository: QTRepository

    public init(qtRepository: QTRepository) {
        self.qtRepository = qtRepository
    }

    public func execute(id: UUID, session: UserSession) async throws -> QuietTime {
        return try await qtRepository.get(id: id, session: session)
    }
}
