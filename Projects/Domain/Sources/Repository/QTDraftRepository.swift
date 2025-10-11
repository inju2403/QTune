//
//  QTDraftRepository.swift
//  Domain
//
//  Created by 이승주 on 10/8/25.
//

import Foundation

/// QT 초안(Draft) 저장소 인터페이스
///
/// 당일 작성 중인 QT 초안을 관리합니다.
/// - 세션 + yyyy-MM-dd 키 기반으로 하루 하나의 초안만 존재
/// - 로컬 우선 저장, 로그인 시 동기화
public protocol QTDraftRepository {
    /// 오늘 날짜의 초안 로드
    ///
    /// - Parameters:
    ///   - session: 현재 사용자 세션
    ///   - date: 기준 날짜 (기본값: 현재)
    ///   - timeZone: 타임존 (기본값: 현재)
    /// - Returns: 초안이 있으면 QuietTime, 없으면 nil
    func loadTodayDraft(
        session: UserSession,
        date: Date,
        timeZone: TimeZone
    ) async throws -> QuietTime?

    /// 오늘 날짜의 초안 저장
    ///
    /// Idempotent 연산으로, 동일 날짜에 대해 항상 덮어씁니다.
    ///
    /// - Parameters:
    ///   - draft: 저장할 초안 (status는 항상 .draft여야 함)
    ///   - session: 현재 사용자 세션
    ///   - date: 기준 날짜
    ///   - timeZone: 타임존
    func saveTodayDraft(
        _ draft: QuietTime,
        session: UserSession,
        date: Date,
        timeZone: TimeZone
    ) async throws

    /// 오늘 날짜의 초안 삭제
    ///
    /// 초안이 없어도 에러 없이 성공합니다.
    ///
    /// - Parameters:
    ///   - session: 현재 사용자 세션
    ///   - date: 기준 날짜
    ///   - timeZone: 타임존
    func discardTodayDraft(
        session: UserSession,
        date: Date,
        timeZone: TimeZone
    ) async throws
}
