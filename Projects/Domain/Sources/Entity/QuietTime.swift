//
//  QuietTime.swift
//  Domain
//
//  Created by 이승주 on 7/26/25.
//

import Foundation

/// QT(Quiet Time) 상태
///
/// - draft: 작성 중인 초안
/// - committed: 완료된 QT (스냅샷 보존)
public enum QuietTimeStatus: Equatable, Hashable {
    case draft
    case committed
}

/// QT(Quiet Time) 엔티티
///
/// 사용자의 묵상 기록을 표현합니다.
/// - draft 상태: 당일 하나만 존재 가능, 언제든 수정/삭제 가능
/// - committed 상태: 영구 보존, 메모 수정 및 즐겨찾기만 가능
public struct QuietTime: Identifiable, Equatable, Hashable {
    public let id: UUID
    public var verse: Verse
    public var memo: String
    public var date: Date
    public var status: QuietTimeStatus
    public var tags: [String]
    public var isFavorite: Bool
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        verse: Verse,
        memo: String,
        date: Date,
        status: QuietTimeStatus,
        tags: [String] = [],
        isFavorite: Bool = false,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.verse = verse
        self.memo = memo
        self.date = date
        self.status = status
        self.tags = tags
        self.isFavorite = isFavorite
        self.updatedAt = updatedAt
    }
}

