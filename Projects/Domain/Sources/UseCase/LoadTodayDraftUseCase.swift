//
//  LoadTodayDraftUseCase.swift
//  Domain
//
//  Created by 이승주 on 10/8/25.
//

import Foundation

/// 오늘 초안 불러오기 유스케이스
///
/// ## 역할
/// - 세션+날짜 기반으로 오늘의 초안을 불러옵니다
/// - 익명/로그인 모두 지원
///
/// ## 사용 예시
/// ```swift
/// let draft = try await loadTodayDraft.execute(session: session, now: Date(), tz: .current)
/// if let draft = draft {
///     // 초안이 있으면 복구 배너 표시
/// }
/// ```
public protocol LoadTodayDraftUseCase {
    /// 오늘 초안 불러오기
    ///
    /// - Parameters:
    ///   - session: 현재 사용자 세션
    ///   - now: 현재 시각 (테스트 가능하도록 주입)
    ///   - timeZone: 타임존 (날짜 계산용)
    /// - Returns: 오늘의 초안 (없으면 nil)
    func execute(session: UserSession, now: Date, timeZone: TimeZone) async throws -> QuietTime?
}

/// LoadTodayDraftUseCase 구현체
public final class LoadTodayDraftInteractor: LoadTodayDraftUseCase {
    private let draftRepository: QTDraftRepository

    public init(draftRepository: QTDraftRepository) {
        self.draftRepository = draftRepository
    }

    public func execute(session: UserSession, now: Date, timeZone: TimeZone) async throws -> QuietTime? {
        return try await draftRepository.loadTodayDraft(session: session, date: now, timeZone: timeZone)
    }
}
