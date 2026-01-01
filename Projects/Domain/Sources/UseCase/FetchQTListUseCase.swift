//
//  FetchQTListUseCase.swift
//  Domain
//
//  Created by 이승주 on 10/8/25.
//

import Foundation

/// QT 목록 조회 유스케이스
///
/// ## 역할
/// - 커밋된 QT 목록을 필터링하여 조회
/// - 날짜 범위, 즐겨찾기 여부, 페이지네이션 지원
///
/// ## 사용 예시
/// ```swift
/// // 전체 목록 (최신순 20개)
/// let allQTs = try await fetchList.execute(query: QTQuery(), session: session)
///
/// // 즐겨찾기만
/// let favorites = try await fetchList.execute(query: .favoritesOnly(), session: session)
///
/// // 날짜 범위 지정
/// let thisWeek = try await fetchList.execute(
///     query: QTQuery(dateRange: DateRange(start: weekStart, end: weekEnd)),
///     session: session
/// )
/// ```
public protocol FetchQTListUseCase {
    /// QT 목록 조회
    ///
    /// - Parameters:
    ///   - query: 조회 조건
    ///   - session: 현재 사용자 세션
    /// - Returns: 조건에 맞는 QuietTime 배열 (최신순)
    func execute(query: QTQuery, session: UserSession) async throws -> [QuietTime]
}

/// FetchQTListUseCase 구현체
public final class FetchQTListInteractor: FetchQTListUseCase {
    private let qtRepository: QTRepository

    public init(qtRepository: QTRepository) {
        self.qtRepository = qtRepository
    }

    public func execute(query: QTQuery, session: UserSession) async throws -> [QuietTime] {
        return try await qtRepository.fetchList(query: query, session: session)
    }
}
