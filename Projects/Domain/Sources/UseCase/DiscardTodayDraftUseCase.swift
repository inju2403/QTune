//
//  DiscardTodayDraftUseCase.swift
//  Domain
//
//  Created by 이승주 on 10/8/25.
//

import Foundation

/// 오늘 초안 삭제 유스케이스
///
/// ## 역할
/// - 초안 복구 거부 시 오늘의 초안을 삭제합니다
/// - 사용자가 "새로 시작" 버튼을 누른 경우
///
/// ## 사용 예시
/// ```swift
/// // 사용자가 초안 복구 거부 선택
/// try await discardDraft.execute(session: session, now: Date(), tz: .current)
/// ```
public protocol DiscardTodayDraftUseCase {
    /// 오늘 초안 삭제
    ///
    /// - Parameters:
    ///   - session: 현재 사용자 세션
    ///   - now: 현재 시각
    ///   - timeZone: 타임존
    func execute(session: UserSession, now: Date, timeZone: TimeZone) async throws
}

/// DiscardTodayDraftUseCase 구현체
public final class DiscardTodayDraftInteractor: DiscardTodayDraftUseCase {
    private let draftRepository: QTDraftRepository

    public init(draftRepository: QTDraftRepository) {
        self.draftRepository = draftRepository
    }

    public func execute(session: UserSession, now: Date, timeZone: TimeZone) async throws {
        try await draftRepository.discardTodayDraft(session: session, date: now, timeZone: timeZone)
    }
}
