//
//  QTRepository.swift
//  Domain
//
//  Created by 이승주 on 10/8/25.
//

import Foundation

/// 날짜 범위
public struct DateRange: Equatable {
    public let start: Date
    public let end: Date

    public init(start: Date, end: Date) {
        self.start = start
        self.end = end
    }
}

/// QT 조회 조건
///
/// FetchQTListUseCase에서 사용하는 필터링/페이지네이션 조건
public struct QTQuery: Equatable {
    public let dateRange: DateRange?
    public let isFavorite: Bool?
    public let searchText: String?
    public let limit: Int
    public let offset: Int

    public init(
        dateRange: DateRange? = nil,
        isFavorite: Bool? = nil,
        searchText: String? = nil,
        limit: Int = 20,
        offset: Int = 0
    ) {
        self.dateRange = dateRange
        self.isFavorite = isFavorite
        self.searchText = searchText
        self.limit = limit
        self.offset = offset
    }

    /// 즐겨찾기 전용 쿼리 생성
    public static func favoritesOnly(limit: Int = 20, offset: Int = 0) -> QTQuery {
        QTQuery(isFavorite: true, limit: limit, offset: offset)
    }
}

/// 완료된 QT 저장소 인터페이스
///
/// committed 상태의 QT를 관리합니다.
/// - 세션 기반으로 사용자별 QT 관리
/// - 메모 수정, 즐겨찾기 토글만 가능
public protocol QTRepository {
    /// 초안을 완료 상태로 커밋
    ///
    /// draft → committed 전환하고 영구 저장합니다.
    ///
    /// - Parameters:
    ///   - draft: 커밋할 초안
    ///   - session: 현재 사용자 세션
    /// - Returns: 커밋된 QuietTime (status == .committed)
    func commit(_ draft: QuietTime, session: UserSession) async throws -> QuietTime

    /// QT 목록 조회
    ///
    /// - Parameters:
    ///   - query: 조회 조건 (날짜 범위, 즐겨찾기 여부, 페이지네이션)
    ///   - session: 현재 사용자 세션
    /// - Returns: 조건에 맞는 QuietTime 배열 (최신순 정렬)
    func fetchList(query: QTQuery, session: UserSession) async throws -> [QuietTime]

    /// 단건 QT 조회
    ///
    /// - Parameters:
    ///   - id: QT ID
    ///   - session: 현재 사용자 세션
    /// - Returns: QuietTime (없으면 DomainError.notFound)
    func get(id: UUID, session: UserSession) async throws -> QuietTime

    /// QT 메모 수정
    ///
    /// committed 상태의 QT에서 메모만 수정 가능합니다.
    ///
    /// - Parameters:
    ///   - id: QT ID
    ///   - newMemo: 새로운 메모 내용
    ///   - session: 현재 사용자 세션
    /// - Returns: 수정된 QuietTime
    func updateMemo(id: UUID, newMemo: String, session: UserSession) async throws -> QuietTime

    /// 즐겨찾기 토글
    ///
    /// - Parameters:
    ///   - id: QT ID
    ///   - session: 현재 사용자 세션
    /// - Returns: 토글 후의 isFavorite 상태 (true/false)
    func toggleFavorite(id: UUID, session: UserSession) async throws -> Bool

    /// QT 전체 업데이트 (템플릿 필드 포함)
    ///
    /// - Parameters:
    ///   - qt: 업데이트할 QuietTime
    ///   - session: 현재 사용자 세션
    /// - Returns: 업데이트된 QuietTime
    func update(_ qt: QuietTime, session: UserSession) async throws -> QuietTime

    /// QT 삭제
    ///
    /// - Parameters:
    ///   - id: QT ID
    ///   - session: 현재 사용자 세션
    func delete(id: UUID, session: UserSession) async throws
}
