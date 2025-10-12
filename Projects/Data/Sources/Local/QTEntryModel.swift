//
//  QTEntryModel.swift
//  Data
//
//  Created by 이승주 on 10/12/25.
//

import Foundation
import SwiftData

/// QT 기록 SwiftData 모델 (Data Layer)
@available(iOS 17, *)
@Model
public final class QTEntryModel {
    // MARK: - 식별/메타
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date
    public var updatedAt: Date
    public var isFavorite: Bool
    public var tags: [String]

    // MARK: - 말씀
    public var verseRef: String
    public var verseBook: String
    public var verseChapter: Int
    public var verseNumber: Int
    public var verseText: String
    public var verseTranslation: String

    // MARK: - AI 생성 필드
    public var korean: String?
    public var rationale: String?

    // MARK: - 상태
    public var status: String  // "draft" | "committed"

    // MARK: - 템플릿
    public var template: String  // "SOAP" | "ACTS"

    // MARK: - SOAP 필드
    public var soapObservation: String?
    public var soapApplication: String?
    public var soapPrayer: String?

    // MARK: - ACTS 필드
    public var actsAdoration: String?
    public var actsConfession: String?
    public var actsThanksgiving: String?
    public var actsSupplication: String?

    // MARK: - Init
    public init(
        id: UUID,
        createdAt: Date,
        updatedAt: Date,
        isFavorite: Bool,
        tags: [String],
        verseRef: String,
        verseBook: String,
        verseChapter: Int,
        verseNumber: Int,
        verseText: String,
        verseTranslation: String,
        korean: String?,
        rationale: String?,
        status: String,
        template: String,
        soapObservation: String?,
        soapApplication: String?,
        soapPrayer: String?,
        actsAdoration: String?,
        actsConfession: String?,
        actsThanksgiving: String?,
        actsSupplication: String?
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isFavorite = isFavorite
        self.tags = tags
        self.verseRef = verseRef
        self.verseBook = verseBook
        self.verseChapter = verseChapter
        self.verseNumber = verseNumber
        self.verseText = verseText
        self.verseTranslation = verseTranslation
        self.korean = korean
        self.rationale = rationale
        self.status = status
        self.template = template
        self.soapObservation = soapObservation
        self.soapApplication = soapApplication
        self.soapPrayer = soapPrayer
        self.actsAdoration = actsAdoration
        self.actsConfession = actsConfession
        self.actsThanksgiving = actsThanksgiving
        self.actsSupplication = actsSupplication
    }
}
