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
    @Published public var showSaveSuccessToast = false
    @Published public var showSaveErrorAlert = false

    // MARK: - Constants
    public let maxCharacters = 500

    // MARK: - Dependencies
    private let commitQTUseCase: CommitQTUseCase
    private let updateQTUseCase: UpdateQTUseCase
    private let session: UserSession

    // MARK: - Properties
    public var editingQT: QuietTime?  // 편집 모드일 때 사용

    // MARK: - Init
    public init(
        commitQTUseCase: CommitQTUseCase,
        updateQTUseCase: UpdateQTUseCase,
        session: UserSession
    ) {
        self.commitQTUseCase = commitQTUseCase
        self.updateQTUseCase = updateQTUseCase
        self.session = session
    }

    // MARK: - 편집 모드 초기화
    public func loadQT(_ qt: QuietTime) {
        editingQT = qt
        selectedTemplate = qt.template == "SOAP" ? .soap : .acts

        if qt.template == "SOAP" {
            soapTemplate.observation = qt.soapObservation ?? ""
            soapTemplate.application = qt.soapApplication ?? ""
            soapTemplate.prayer = qt.soapPrayer ?? ""
        } else {
            actsTemplate.adoration = qt.actsAdoration ?? ""
            actsTemplate.confession = qt.actsConfession ?? ""
            actsTemplate.thanksgiving = qt.actsThanksgiving ?? ""
            actsTemplate.supplication = qt.actsSupplication ?? ""
        }
    }

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

    // MARK: - Save Logic
    /// QT 저장 (신규 또는 편집)
    public func saveQT(draft: Domain.QuietTime) async {
        do {
            var qtToSave = draft
            qtToSave.template = selectedTemplate.rawValue
            qtToSave.updatedAt = Date()

            // 템플릿별 필드 설정
            if selectedTemplate == .soap {
                qtToSave.soapObservation = soapTemplate.observation
                qtToSave.soapApplication = soapTemplate.application
                qtToSave.soapPrayer = soapTemplate.prayer
                qtToSave.actsAdoration = nil
                qtToSave.actsConfession = nil
                qtToSave.actsThanksgiving = nil
                qtToSave.actsSupplication = nil
            } else {
                qtToSave.actsAdoration = actsTemplate.adoration
                qtToSave.actsConfession = actsTemplate.confession
                qtToSave.actsThanksgiving = actsTemplate.thanksgiving
                qtToSave.actsSupplication = actsTemplate.supplication
                qtToSave.soapObservation = nil
                qtToSave.soapApplication = nil
                qtToSave.soapPrayer = nil
            }

            if let existingQT = editingQT {
                // 편집 모드: 업데이트
                var updated = existingQT
                updated.template = qtToSave.template
                updated.soapObservation = qtToSave.soapObservation
                updated.soapApplication = qtToSave.soapApplication
                updated.soapPrayer = qtToSave.soapPrayer
                updated.actsAdoration = qtToSave.actsAdoration
                updated.actsConfession = qtToSave.actsConfession
                updated.actsThanksgiving = qtToSave.actsThanksgiving
                updated.actsSupplication = qtToSave.actsSupplication
                updated.updatedAt = Date()

                _ = try await updateQTUseCase.execute(qt: updated, session: session)
            } else {
                // 신규 작성: 커밋
                qtToSave.status = .draft
                _ = try await commitQTUseCase.execute(draft: qtToSave, session: session)
            }

            await MainActor.run {
                showSaveSuccessToast = true
            }
        } catch {
            await MainActor.run {
                showSaveErrorAlert = true
            }
        }
    }
}
