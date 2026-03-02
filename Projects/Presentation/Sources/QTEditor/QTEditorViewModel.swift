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

        case .updateFreeContent(let text):
            state.freeTemplate.content = text

        case .saveQT(let draft):
            // 이미 저장 중이면 무시
            guard !state.isSaving else {
                print("⚠️ [QTEditorViewModel] Already saving, ignoring duplicate save request")
                return
            }
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
            qt.freeContent == nil

        // 신규 작성이 아닐 때만 editingQT 설정 (UPDATE 모드)
        if !isNewDraft {
            state.editingQT = qt
        }

        state.selectedTemplate = qt.template == "SOAP" ? .soap : .free

        if qt.template == "SOAP" {
            state.soapTemplate.observation = qt.soapObservation ?? ""
            state.soapTemplate.application = qt.soapApplication ?? ""
            state.soapTemplate.prayer = qt.soapPrayer ?? ""
        } else if qt.template == "FREE" {
            state.freeTemplate.content = qt.freeContent ?? ""
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

        // 저장 시작
        state.isSaving = true
        defer {
            // 저장 완료/실패 시 플래그 해제
            state.isSaving = false
        }

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
                qtToSave.freeContent = nil
            } else if state.selectedTemplate == .free {
                print("   FREE - Content: \(state.freeTemplate.content.count)")
                qtToSave.freeContent = state.freeTemplate.content
                qtToSave.soapObservation = nil
                qtToSave.soapApplication = nil
                qtToSave.soapPrayer = nil
            }

            let savedQT: QuietTime
            if let existingQT = state.editingQT {
                // 편집 모드: 업데이트
                print("   Mode: UPDATE existing QT")
                var updated = existingQT
                updated.template = qtToSave.template
                updated.soapObservation = qtToSave.soapObservation
                updated.soapApplication = qtToSave.soapApplication
                updated.soapPrayer = qtToSave.soapPrayer
                updated.freeContent = qtToSave.freeContent
                updated.updatedAt = Date()

                print("   Calling updateQTUseCase...")
                savedQT = try await updateQTUseCase.execute(qt: updated, session: session)
                print("   ✅ Update succeeded")
            } else {
                // 신규 작성: 커밋
                print("   Mode: COMMIT new QT")
                qtToSave.status = .draft
                print("   Calling commitQTUseCase...")
                savedQT = try await commitQTUseCase.execute(draft: qtToSave, session: session)
                print("   ✅ Commit succeeded")
            }

            await MainActor.run {
                NotificationCenter.default.post(
                    name: .qtDidChange,
                    object: state.editingQT != nil
                        ? QTChangeType.updated(savedQT)
                        : QTChangeType.created(savedQT)
                )
                state.showSaveSuccessToast = true
            }
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
