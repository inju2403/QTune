//
//  QTEditorViewModel.swift
//  Presentation
//
//  Created by 이승주 on 10/12/25.
//

import Foundation
import Domain

/// QT 작성 화면 ViewModel
@Observable
public final class QTEditorViewModel {
    // MARK: - State
    public private(set) var state: QTEditorState

    // MARK: - Constants
    public let maxCharacters = 500

    // MARK: - Dependencies
    private let commitQTUseCase: CommitQTUseCase
    private let updateQTUseCase: UpdateQTUseCase
    private let session: UserSession

    // MARK: - Init
    public init(
        commitQTUseCase: CommitQTUseCase,
        updateQTUseCase: UpdateQTUseCase,
        session: UserSession,
        initialState: QTEditorState = QTEditorState()
    ) {
        self.commitQTUseCase = commitQTUseCase
        self.updateQTUseCase = updateQTUseCase
        self.session = session
        self.state = initialState
    }

    // MARK: - Send Action
    public func send(_ action: QTEditorAction) {
        switch action {
        case .loadQT(let qt):
            loadQT(qt)

        case .switchTemplate(let template):
            state.selectedTemplate = template

        case .updateSOAPObservation(let text):
            state.soapTemplate.observation = text

        case .updateSOAPApplication(let text):
            state.soapTemplate.application = text

        case .updateSOAPPrayer(let text):
            state.soapTemplate.prayer = text

        case .updateACTSAdoration(let text):
            state.actsTemplate.adoration = text

        case .updateACTSConfession(let text):
            state.actsTemplate.confession = text

        case .updateACTSThanksgiving(let text):
            state.actsTemplate.thanksgiving = text

        case .updateACTSSupplication(let text):
            state.actsTemplate.supplication = text

        case .saveQT(let draft):
            Task { await saveQT(draft: draft) }
        }
    }

    // MARK: - 편집 모드 초기화
    private func loadQT(_ qt: QuietTime) {
        // status가 draft이고 템플릿 필드가 비어있으면 신규 작성
        let isNewDraft = qt.status == .draft &&
            qt.soapObservation == nil &&
            qt.soapApplication == nil &&
            qt.soapPrayer == nil &&
            qt.actsAdoration == nil &&
            qt.actsConfession == nil &&
            qt.actsThanksgiving == nil &&
            qt.actsSupplication == nil

        // 신규 작성이 아닐 때만 editingQT 설정 (UPDATE 모드)
        if !isNewDraft {
            state.editingQT = qt
        }

        state.selectedTemplate = qt.template == "SOAP" ? .soap : .acts

        if qt.template == "SOAP" {
            state.soapTemplate.observation = qt.soapObservation ?? ""
            state.soapTemplate.application = qt.soapApplication ?? ""
            state.soapTemplate.prayer = qt.soapPrayer ?? ""
        } else {
            state.actsTemplate.adoration = qt.actsAdoration ?? ""
            state.actsTemplate.confession = qt.actsConfession ?? ""
            state.actsTemplate.thanksgiving = qt.actsThanksgiving ?? ""
            state.actsTemplate.supplication = qt.actsSupplication ?? ""
        }
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
    private func saveQT(draft: Domain.QuietTime) async {
        print("🔵 [QTEditorViewModel] Starting saveQT")
        print("   Draft ID: \(draft.id)")
        print("   Editing QT: \(state.editingQT?.id.uuidString ?? "nil")")
        print("   Selected Template: \(state.selectedTemplate)")

        do {
            var qtToSave = draft
            qtToSave.template = state.selectedTemplate.rawValue
            qtToSave.updatedAt = Date()

            // 템플릿별 필드 설정
            if state.selectedTemplate == .soap {
                print("   SOAP - O: \(state.soapTemplate.observation.count), A: \(state.soapTemplate.application.count), P: \(state.soapTemplate.prayer.count)")
                qtToSave.soapObservation = state.soapTemplate.observation
                qtToSave.soapApplication = state.soapTemplate.application
                qtToSave.soapPrayer = state.soapTemplate.prayer
                qtToSave.actsAdoration = nil
                qtToSave.actsConfession = nil
                qtToSave.actsThanksgiving = nil
                qtToSave.actsSupplication = nil
            } else {
                print("   ACTS - A: \(state.actsTemplate.adoration.count), C: \(state.actsTemplate.confession.count), T: \(state.actsTemplate.thanksgiving.count), S: \(state.actsTemplate.supplication.count)")
                qtToSave.actsAdoration = state.actsTemplate.adoration
                qtToSave.actsConfession = state.actsTemplate.confession
                qtToSave.actsThanksgiving = state.actsTemplate.thanksgiving
                qtToSave.actsSupplication = state.actsTemplate.supplication
                qtToSave.soapObservation = nil
                qtToSave.soapApplication = nil
                qtToSave.soapPrayer = nil
            }

            if let existingQT = state.editingQT {
                // 편집 모드: 업데이트
                print("   Mode: UPDATE existing QT")
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

                print("   Calling updateQTUseCase...")
                _ = try await updateQTUseCase.execute(qt: updated, session: session)
                print("   ✅ Update succeeded")
            } else {
                // 신규 작성: 커밋
                print("   Mode: COMMIT new QT")
                qtToSave.status = .draft
                print("   Calling commitQTUseCase...")
                _ = try await commitQTUseCase.execute(draft: qtToSave, session: session)
                print("   ✅ Commit succeeded")
            }

            state.showSaveSuccessToast = true
        } catch {
            print("🔴 [QTEditorViewModel] Save failed: \(error)")
            if let localizedError = error as? LocalizedError {
                print("   Description: \(localizedError.errorDescription ?? "none")")
                print("   Reason: \(localizedError.failureReason ?? "none")")
            }
            state.showSaveErrorAlert = true
        }
    }
}
