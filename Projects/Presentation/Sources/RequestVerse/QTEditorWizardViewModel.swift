//
//  QTEditorWizardViewModel.swift
//  Presentation
//
//  Created by 이승주 on 11/28/25.
//

import Foundation
import Domain

/// QT 작성 마법사 화면 ViewModel
@Observable
public final class QTEditorWizardViewModel {
    // MARK: - State
    public private(set) var state: QTEditorWizardState

    // MARK: - Dependencies
    private let commitQTUseCase: CommitQTUseCase
    private let session: UserSession

    // MARK: - Callbacks
    public var onSaveComplete: (() -> Void)?

    // MARK: - Init
    public init(
        commitQTUseCase: CommitQTUseCase,
        session: UserSession,
        initialState: QTEditorWizardState
    ) {
        self.commitQTUseCase = commitQTUseCase
        self.session = session
        self.state = initialState
    }

    // MARK: - Send Action
    public func send(_ action: QTEditorWizardAction) {
        switch action {
        case .stepNext:
            stepNext()
        case .stepPrevious:
            stepPrevious()
        case .updateObservation(let text):
            state.observation = text
        case .updateApplication(let text):
            state.application = text
        case .updatePrayer(let text):
            state.prayer = text
        case .updateFreeContent(let text):
            state.freeContent = text
        case .save:
            Task { await saveQT() }
        }
    }

    // MARK: - Helpers
    public var isFirstStep: Bool {
        switch state.template {
        case .soap:
            return state.soapStep == .observation
        case .free:
            return true
        }
    }

    public var isLastStep: Bool {
        switch state.template {
        case .soap:
            return state.soapStep == .prayer
        case .free:
            return true
        }
    }

    public var nextTitle: String {
        isLastStep ? "저장" : "다음"
    }

    public var currentStepIndex: Int {
        switch state.template {
        case .soap:
            return state.soapStep.rawValue
        case .free:
            return 0
        }
    }

    public var totalSteps: Int {
        switch state.template {
        case .soap:
            return SoapStep.allCases.count
        case .free:
            return 1
        }
    }

    // MARK: - Step Navigation
    private func stepNext() {
        switch state.template {
        case .soap:
            if let next = SoapStep(rawValue: state.soapStep.rawValue + 1) {
                state.soapStep = next
            } else {
                // 마지막 단계에서 저장
                send(.save)
            }
        case .free:
            // 자유 묵상은 단일 단계이므로 바로 저장
            send(.save)
        }
    }

    private func stepPrevious() {
        switch state.template {
        case .soap:
            if let prev = SoapStep(rawValue: state.soapStep.rawValue - 1) {
                state.soapStep = prev
            }
        case .free:
            // 자유 묵상은 단일 단계이므로 이전 단계 없음
            break
        }
    }

    // MARK: - Save Logic
    private func saveQT() async {
        guard !state.isSaving else { return }

        await MainActor.run {
            state.isSaving = true
        }

        do {
            // QuietTime 생성
            var qt = QuietTime(
                verse: state.verse,
                secondaryVerse: state.secondaryVerse,
                korean: state.explKR,
                rationale: state.rationale,
                suggestedPrayer: state.suggestedPrayer,
                date: Date(),
                status: .draft,
                template: state.template == .soap ? "SOAP" : "FREE"
            )

            // 템플릿별 필드 설정
            if state.template == .soap {
                qt.soapObservation = state.observation
                qt.soapApplication = state.application
                qt.soapPrayer = state.prayer
            } else {
                qt.freeContent = state.freeContent
            }

            // 저장
            let savedQT = try await commitQTUseCase.execute(draft: qt, session: session)

            await MainActor.run {
                state.isSaving = false
                state.showSaveSuccessToast = true

                // 새 QT ID를 AppStorage에 저장 (QTListView가 없어도 전달 가능)
                UserDefaults.standard.set(savedQT.id.uuidString, forKey: "pendingNewQTId")

                // Notification도 발송 (이미 QTListView가 있는 경우를 위해)
                NotificationCenter.default.post(
                    name: .qtDidChange,
                    object: QTChangeType.created(savedQT)
                )

                // 1초 후 기록 탭으로 이동
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    self?.onSaveComplete?()
                }
            }
        } catch {
            // 실패
            await MainActor.run {
                state.isSaving = false
                state.showSaveErrorAlert = true
            }
        }
    }
}
