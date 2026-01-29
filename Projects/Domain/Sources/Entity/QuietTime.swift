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
    public var secondaryVerse: Verse?  // 비교 역본
    public var memo: String          // Deprecated: 템플릿 필드로 대체됨
    public var korean: String?       // GPT 한글 해설
    public var rationale: String?    // 추천 이유
    public var date: Date
    public var status: QuietTimeStatus
    public var tags: [String]
    public var isFavorite: Bool
    public var updatedAt: Date

    // MARK: - 템플릿
    public var template: String      // "SOAP" | "ACTS"

    // MARK: - SOAP 필드
    public var soapObservation: String?
    public var soapApplication: String?
    public var soapPrayer: String?

    // MARK: - ACTS 필드
    public var actsAdoration: String?
    public var actsConfession: String?
    public var actsThanksgiving: String?
    public var actsSupplication: String?

    public init(
        id: UUID = UUID(),
        verse: Verse,
        secondaryVerse: Verse? = nil,
        memo: String = "",
        korean: String? = nil,
        rationale: String? = nil,
        date: Date,
        status: QuietTimeStatus,
        tags: [String] = [],
        isFavorite: Bool = false,
        updatedAt: Date = .now,
        template: String = "SOAP",
        soapObservation: String? = nil,
        soapApplication: String? = nil,
        soapPrayer: String? = nil,
        actsAdoration: String? = nil,
        actsConfession: String? = nil,
        actsThanksgiving: String? = nil,
        actsSupplication: String? = nil
    ) {
        self.id = id
        self.verse = verse
        self.secondaryVerse = secondaryVerse
        self.memo = memo
        self.korean = korean
        self.rationale = rationale
        self.date = date
        self.status = status
        self.tags = tags
        self.isFavorite = isFavorite
        self.updatedAt = updatedAt
        self.template = template
        self.soapObservation = soapObservation
        self.soapApplication = soapApplication
        self.soapPrayer = soapPrayer
        self.actsAdoration = actsAdoration
        self.actsConfession = actsConfession
        self.actsThanksgiving = actsThanksgiving
        self.actsSupplication = actsSupplication
    }

    /// 리스트용 미리보기 텍스트 (최대 120자)
    public var preview: String {
        let content: String
        if template == "SOAP" {
            content = soapObservation ?? soapApplication ?? soapPrayer ?? ""
        } else {
            content = actsAdoration ?? actsConfession ?? actsThanksgiving ?? actsSupplication ?? ""
        }

        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count > 120 {
            return String(trimmed.prefix(120)) + "..."
        }
        return trimmed
    }
}

