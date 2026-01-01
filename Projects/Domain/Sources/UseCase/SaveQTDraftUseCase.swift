//
//  SaveQTDraftUseCase.swift
//  Domain
//
//  Created by 이승주 on 10/8/25.
//

import Foundation

/// QT 초안 저장 유스케이스
///
/// ## 역할
/// - 말씀 생성 후 임시 저장 (draft 상태)
/// - 세션+날짜 기반으로 저장 (하루에 하나만)
///
/// ## 사용 예시
/// ```swift
/// let draft = QuietTime(
///     id: UUID(),
///     verse: generatedVerse.verse,
///     memo: userMemo,
///     date: Date(),
///     status: .draft
/// )
/// try await saveDraft.execute(draft: draft, session: session, now: Date(), tz: .current)
/// ```
public protocol SaveQTDraftUseCase {
    /// QT 초안 저장
    ///
    /// - Parameters:
    ///   - draft: 저장할 초안 (status는 .draft여야 함)
    ///   - session: 현재 사용자 세션
    ///   - now: 현재 시각
    ///   - timeZone: 타임존
    func execute(draft: QuietTime, session: UserSession, now: Date, timeZone: TimeZone) async throws
}

/// SaveQTDraftUseCase 구현체
public final class SaveQTDraftInteractor: SaveQTDraftUseCase {
    private let draftRepository: QTDraftRepository

    public init(draftRepository: QTDraftRepository) {
        self.draftRepository = draftRepository
    }

    public func execute(draft: QuietTime, session: UserSession, now: Date, timeZone: TimeZone) async throws {
        // 검증: draft 상태인지 확인
        guard draft.status == .draft else {
            throw DomainError.validationFailed("Only draft status can be saved as draft")
        }

        try await draftRepository.saveTodayDraft(draft, session: session, date: now, timeZone: timeZone)
    }
}
