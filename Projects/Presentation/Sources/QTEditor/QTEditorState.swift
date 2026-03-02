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

    public init(
        selectedTemplate: QTTemplateType = .soap,
        soapTemplate: SOAPTemplate = SOAPTemplate(),
        freeTemplate: FreeTemplate = FreeTemplate(),
        showSaveSuccessToast: Bool = false,
        showSaveErrorAlert: Bool = false,
        editingQT: QuietTime? = nil,
        isSaving: Bool = false
    ) {
        self.selectedTemplate = selectedTemplate
        self.soapTemplate = soapTemplate
        self.freeTemplate = freeTemplate
        self.showSaveSuccessToast = showSaveSuccessToast
        self.showSaveErrorAlert = showSaveErrorAlert
        self.editingQT = editingQT
        self.isSaving = isSaving
    }
}
