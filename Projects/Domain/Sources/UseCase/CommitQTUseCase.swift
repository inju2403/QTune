//
//  CommitQTUseCase.swift
//  Domain
//
//  Created by 이승주 on 10/8/25.
//

import Foundation

/// QT 커밋 유스케이스
///
/// ## 역할
/// - 초안(draft)을 완료(committed) 상태로 전환
/// - 영구 저장 (로컬 DB + 서버 동기화)
///
/// ## 사용 예시
/// ```swift
/// let committedQT = try await commitQT.execute(draft: todayDraft, session: session)
/// // 커밋 후 초안 삭제 필요
/// ```
public protocol CommitQTUseCase {
    /// 초안을 커밋
    ///
    /// - Parameters:
    ///   - draft: 커밋할 초안 (status == .draft)
    ///   - session: 현재 사용자 세션
    /// - Returns: 커밋된 QuietTime (status == .committed)
    func execute(draft: QuietTime, session: UserSession) async throws -> QuietTime
}

/// CommitQTUseCase 구현체
public final class CommitQTInteractor: CommitQTUseCase {
    private let qtRepository: QTRepository

    public init(qtRepository: QTRepository) {
        self.qtRepository = qtRepository
    }

    public func execute(draft: QuietTime, session: UserSession) async throws -> QuietTime {
        // 검증: draft 상태인지 확인
        guard draft.status == .draft else {
            throw DomainError.validationFailed("Only draft status can be committed")
        }

        return try await qtRepository.commit(draft, session: session)
    }
}
