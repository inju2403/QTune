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
    public var verse: Verse

    // 단계 관리
    public var soapStep: SoapStep
    public var actsStep: ActsStep

    // SOAP 입력값
    public var observation: String
    public var application: String
    public var prayer: String

    // ACTS 입력값
    public var adoration: String
    public var confession: String
    public var thanksgiving: String
    public var supplication: String

    // 저장 상태
    public var isSaving: Bool
    public var showSaveSuccessToast: Bool
    public var showSaveErrorAlert: Bool

    public init(
        template: TemplateKind,
        verseEN: String,
        verseRef: String,
        explKR: String,
        verse: Verse,
        soapStep: SoapStep = .observation,
        actsStep: ActsStep = .adoration,
        observation: String = "",
        application: String = "",
        prayer: String = "",
        adoration: String = "",
        confession: String = "",
        thanksgiving: String = "",
        supplication: String = "",
        isSaving: Bool = false,
        showSaveSuccessToast: Bool = false,
        showSaveErrorAlert: Bool = false
    ) {
        self.template = template
        self.verseEN = verseEN
        self.verseRef = verseRef
        self.explKR = explKR
        self.verse = verse
        self.soapStep = soapStep
        self.actsStep = actsStep
        self.observation = observation
        self.application = application
        self.prayer = prayer
        self.adoration = adoration
        self.confession = confession
        self.thanksgiving = thanksgiving
        self.supplication = supplication
        self.isSaving = isSaving
        self.showSaveSuccessToast = showSaveSuccessToast
        self.showSaveErrorAlert = showSaveErrorAlert
    }
}
