//
//  QTEditorViewModel.swift
//  Presentation
//
//  Created by 이승주 on 10/12/25.
//

import Foundation
import SwiftUI
import Domain

/// QT 작성 화면 ViewModel
public final class QTEditorViewModel: ObservableObject {
    // MARK: - Published State
    @Published public var selectedTemplate: QTTemplateType = .soap
    @Published public var soapTemplate = SOAPTemplate()
    @Published public var actsTemplate = ACTSTemplate()

    // MARK: - Constants
    public let maxCharacters = 500

    // MARK: - Init
    public init() {}

    // MARK: - Actions
    public func switchTemplate(to template: QTTemplateType) {
        selectedTemplate = template
    }

    public func updateSOAPObservation(_ text: String) {
        soapTemplate.observation = text
    }

    public func updateSOAPApplication(_ text: String) {
        soapTemplate.application = text
    }

    public func updateSOAPPrayer(_ text: String) {
        soapTemplate.prayer = text
    }

    public func updateACTSAdoration(_ text: String) {
        actsTemplate.adoration = text
    }

    public func updateACTSConfession(_ text: String) {
        actsTemplate.confession = text
    }

    public func updateACTSThanksgiving(_ text: String) {
        actsTemplate.thanksgiving = text
    }

    public func updateACTSSupplication(_ text: String) {
        actsTemplate.supplication = text
    }

    // MARK: - Validation Helpers
    public func characterCount(for text: String) -> String {
        let count = text.count
        return "\(count)/\(maxCharacters)"
    }

    public func isOverLimit(for text: String) -> Bool {
        text.count > maxCharacters
    }

    public func isEmptyOrWhitespace(_ text: String) -> Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
