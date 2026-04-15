//
//  QTEditorWizardState.swift
//  Presentation
//
//  Created by 이승주 on 11/28/25.
//

import Foundation
import Domain

/// QT 작성 마법사 화면 State
public struct QTEditorWizardState: Equatable {
    // 템플릿 및 초기 데이터
    public var template: TemplateKind
    public var verseEN: String
    public var verseRef: String
    public var explKR: String
    public var rationale: String
    public var suggestedPrayer: String?
    public var verse: Verse
    public var secondaryVerse: Verse?

    // 단계 관리
    public var soapStep: SoapStep
    public var actsStep: ACTSStep

    // SOAP 입력값
    public var observation: String
    public var application: String
    public var prayer: String

    // ACTS 입력값
    public var adoration: String
    public var confession: String
    public var thanksgiving: String
    public var supplication: String

    // 자유 묵상 입력값
    public var freeContent: String

    // 저장 상태
    public var isSaving: Bool
    public var showSaveSuccessToast: Bool
    public var showSaveErrorAlert: Bool

    // 기도문 생성 상태
    public var isPrayerAvailable: Bool
    public var isPrayerLoading: Bool
    public var prayerError: String?
    public var showPrayerSheet: Bool

    // 해설 생성 상태
    public var isExplanationAvailable: Bool
    public var isExplanationLoading: Bool
    public var explanationError: String?
    public var showExplanationSheet: Bool

    public init(
        template: TemplateKind,
        verseEN: String,
        verseRef: String,
        explKR: String,
        rationale: String,
        suggestedPrayer: String?,
        verse: Verse,
        secondaryVerse: Verse? = nil,
        soapStep: SoapStep = .observation,
        actsStep: ACTSStep = .adoration,
        observation: String = "",
        application: String = "",
        prayer: String = "",
        adoration: String = "",
        confession: String = "",
        thanksgiving: String = "",
        supplication: String = "",
        freeContent: String = "",
        isSaving: Bool = false,
        showSaveSuccessToast: Bool = false,
        showSaveErrorAlert: Bool = false,
        isPrayerAvailable: Bool = false,
        isPrayerLoading: Bool = false,
        prayerError: String? = nil,
        showPrayerSheet: Bool = false,
        isExplanationAvailable: Bool = false,
        isExplanationLoading: Bool = false,
        explanationError: String? = nil,
        showExplanationSheet: Bool = false
    ) {
        self.template = template
        self.verseEN = verseEN
        self.verseRef = verseRef
        self.explKR = explKR
        self.rationale = rationale
        self.suggestedPrayer = suggestedPrayer
        self.verse = verse
        self.secondaryVerse = secondaryVerse
        self.soapStep = soapStep
        self.actsStep = actsStep
        self.observation = observation
        self.application = application
        self.prayer = prayer
        self.adoration = adoration
        self.confession = confession
        self.thanksgiving = thanksgiving
        self.supplication = supplication
        self.freeContent = freeContent
        self.isSaving = isSaving
        self.showSaveSuccessToast = showSaveSuccessToast
        self.showSaveErrorAlert = showSaveErrorAlert
        self.isPrayerAvailable = isPrayerAvailable
        self.isPrayerLoading = isPrayerLoading
        self.prayerError = prayerError
        self.showPrayerSheet = showPrayerSheet
        self.isExplanationAvailable = isExplanationAvailable
        self.isExplanationLoading = isExplanationLoading
        self.explanationError = explanationError
        self.showExplanationSheet = showExplanationSheet
    }

    /// 현재 스텝의 입력값이 유효한지 확인
    public var isCurrentStepValid: Bool {
        switch template {
        case .soap:
            switch soapStep {
            case .observation:
                return !observation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            case .application:
                return !application.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            case .prayer:
                return !prayer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
        case .acts:
            switch actsStep {
            case .adoration:
                return !adoration.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            case .confession:
                return !confession.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            case .thanksgiving:
                return !thanksgiving.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            case .supplication:
                return !supplication.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
        case .free:
            return !freeContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}
