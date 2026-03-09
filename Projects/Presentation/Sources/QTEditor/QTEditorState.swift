//
//  QTEditorState.swift
//  Presentation
//
//  Created by 이승주 on 10/12/25.
//

import Foundation
import Domain

/// QT 작성 화면 State
public struct QTEditorState: Equatable {
    public var selectedTemplate: QTTemplateType
    public var soapTemplate: SOAPTemplate
    public var freeTemplate: FreeTemplate
    public var showSaveSuccessToast: Bool
    public var showSaveErrorAlert: Bool
    public var editingQT: QuietTime?
    public var isSaving: Bool

    // 기도문 관련
    public var isPrayerAvailable: Bool = false
    public var showPrayerSheet: Bool = false
    public var suggestedPrayer: String? = nil
    public var isPrayerLoading: Bool = false
    public var prayerError: String? = nil

    public init(
        selectedTemplate: QTTemplateType = .soap,
        soapTemplate: SOAPTemplate = SOAPTemplate(),
        freeTemplate: FreeTemplate = FreeTemplate(),
        showSaveSuccessToast: Bool = false,
        showSaveErrorAlert: Bool = false,
        editingQT: QuietTime? = nil,
        isSaving: Bool = false,
        isPrayerAvailable: Bool = false,
        showPrayerSheet: Bool = false,
        suggestedPrayer: String? = nil,
        isPrayerLoading: Bool = false,
        prayerError: String? = nil
    ) {
        self.selectedTemplate = selectedTemplate
        self.soapTemplate = soapTemplate
        self.freeTemplate = freeTemplate
        self.showSaveSuccessToast = showSaveSuccessToast
        self.showSaveErrorAlert = showSaveErrorAlert
        self.editingQT = editingQT
        self.isSaving = isSaving
        self.isPrayerAvailable = isPrayerAvailable
        self.showPrayerSheet = showPrayerSheet
        self.suggestedPrayer = suggestedPrayer
        self.isPrayerLoading = isPrayerLoading
        self.prayerError = prayerError
    }
}
