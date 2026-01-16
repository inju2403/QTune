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
        case .updateAdoration(let text):
            state.adoration = text
        case .updateConfession(let text):
            state.confession = text
        case .updateThanksgiving(let text):
            state.thanksgiving = text
        case .updateSupplication(let text):
            state.supplication = text
        case .save:
            Task { await saveQT() }
        }
    }

    // MARK: - Helpers
    public var isFirstStep: Bool {
        switch state.template {
        case .soap:
            return state.soapStep == .observation
        case .acts:
            return state.actsStep == .adoration
        }
    }

    public var isLastStep: Bool {
        switch state.template {
        case .soap:
            return state.soapStep == .prayer
        case .acts:
            return state.actsStep == .supplication
        }
    }

    public var nextTitle: String {
        isLastStep ? "저장" : "다음"
    }

    public var currentStepIndex: Int {
        switch state.template {
        case .soap:
            return state.soapStep.rawValue
        case .acts:
            return state.actsStep.rawValue
        }
    }

    public var totalSteps: Int {
        switch state.template {
        case .soap:
            return SoapStep.allCases.count
        case .acts:
            return ActsStep.allCases.count
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
        case .acts:
            if let next = ActsStep(rawValue: state.actsStep.rawValue + 1) {
                state.actsStep = next
            } else {
                // 마지막 단계에서 저장
                send(.save)
            }
        }
    }

    private func stepPrevious() {
        switch state.template {
        case .soap:
            if let prev = SoapStep(rawValue: state.soapStep.rawValue - 1) {
                state.soapStep = prev
            }
        case .acts:
            if let prev = ActsStep(rawValue: state.actsStep.rawValue - 1) {
                state.actsStep = prev
            }
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
                korean: state.explKR,
                rationale: state.rationale,
                date: Date(),
                status: .draft,
                template: state.template == .soap ? "SOAP" : "ACTS"
            )

            // 템플릿별 필드 설정
            if state.template == .soap {
                qt.soapObservation = state.observation
                qt.soapApplication = state.application
                qt.soapPrayer = state.prayer
            } else {
                qt.actsAdoration = state.adoration
                qt.actsConfession = state.confession
                qt.actsThanksgiving = state.thanksgiving
                qt.actsSupplication = state.supplication
            }

            // 저장
            _ = try await commitQTUseCase.execute(draft: qt, session: session)

            // 성공 - QT 변경 알림
            NotificationCenter.default.post(name: .qtDidChange, object: nil)

            await MainActor.run {
                state.isSaving = false
                state.showSaveSuccessToast = true

                // 1초 후 콜백 실행
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
