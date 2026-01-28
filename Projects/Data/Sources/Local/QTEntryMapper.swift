//
//  QTEntryMapper.swift
//  Data
//
//  Created by 이승주 on 10/12/25.
//

import Foundation
import Domain

/// QTEntryModel ↔ QuietTime 변환
@available(iOS 17, *)
extension QTEntryModel {
    /// SwiftData 모델 → Domain 엔티티
    func toDomain() -> QuietTime {
        let verse = Verse(
            book: verseBook,
            chapter: verseChapter,
            verse: verseNumber,
            text: verseText,
            translation: verseTranslation
        )

        // 대조역본이 있으면 생성
        let secondaryVerse: Verse? = {
            guard let book = secondaryVerseBook,
                  let chapter = secondaryVerseChapter,
                  let number = secondaryVerseNumber,
                  let text = secondaryVerseText,
                  let translation = secondaryVerseTranslation else {
                return nil
            }
            return Verse(
                book: book,
                chapter: chapter,
                verse: number,
                text: text,
                translation: translation
            )
        }()

        let qtStatus: QuietTimeStatus = (status == "committed") ? .committed : .draft

        return QuietTime(
            id: id,
            verse: verse,
            secondaryVerse: secondaryVerse,
            memo: "",  // Deprecated
            korean: korean,
            rationale: rationale,
            date: createdAt,
            status: qtStatus,
            tags: tags,
            isFavorite: isFavorite,
            updatedAt: updatedAt,
            template: template,
            soapObservation: soapObservation,
            soapApplication: soapApplication,
            soapPrayer: soapPrayer,
            actsAdoration: actsAdoration,
            actsConfession: actsConfession,
            actsThanksgiving: actsThanksgiving,
            actsSupplication: actsSupplication
        )
    }

    /// Domain 엔티티 → SwiftData 모델 (신규 생성)
    static func fromDomain(_ qt: QuietTime) -> QTEntryModel {
        let statusString = (qt.status == .committed) ? "committed" : "draft"

        return QTEntryModel(
            id: qt.id,
            createdAt: qt.date,
            updatedAt: qt.updatedAt,
            isFavorite: qt.isFavorite,
            tags: qt.tags,
            verseRef: qt.verse.id,
            verseBook: qt.verse.book,
            verseChapter: qt.verse.chapter,
            verseNumber: qt.verse.verse,
            verseText: qt.verse.text,
            verseTranslation: qt.verse.translation,
            secondaryVerseBook: qt.secondaryVerse?.book,
            secondaryVerseChapter: qt.secondaryVerse?.chapter,
            secondaryVerseNumber: qt.secondaryVerse?.verse,
            secondaryVerseText: qt.secondaryVerse?.text,
            secondaryVerseTranslation: qt.secondaryVerse?.translation,
            korean: qt.korean,
            rationale: qt.rationale,
            status: statusString,
            template: qt.template,
            soapObservation: qt.soapObservation,
            soapApplication: qt.soapApplication,
            soapPrayer: qt.soapPrayer,
            actsAdoration: qt.actsAdoration,
            actsConfession: qt.actsConfession,
            actsThanksgiving: qt.actsThanksgiving,
            actsSupplication: qt.actsSupplication
        )
    }

    /// Domain 엔티티의 값으로 기존 모델 업데이트
    func updateFrom(_ qt: QuietTime) {
        self.updatedAt = qt.updatedAt
        self.isFavorite = qt.isFavorite
        self.tags = qt.tags
        self.secondaryVerseBook = qt.secondaryVerse?.book
        self.secondaryVerseChapter = qt.secondaryVerse?.chapter
        self.secondaryVerseNumber = qt.secondaryVerse?.verse
        self.secondaryVerseText = qt.secondaryVerse?.text
        self.secondaryVerseTranslation = qt.secondaryVerse?.translation
        self.korean = qt.korean
        self.rationale = qt.rationale
        self.status = (qt.status == .committed) ? "committed" : "draft"
        self.template = qt.template
        self.soapObservation = qt.soapObservation
        self.soapApplication = qt.soapApplication
        self.soapPrayer = qt.soapPrayer
        self.actsAdoration = qt.actsAdoration
        self.actsConfession = qt.actsConfession
        self.actsThanksgiving = qt.actsThanksgiving
        self.actsSupplication = qt.actsSupplication
    }
}
