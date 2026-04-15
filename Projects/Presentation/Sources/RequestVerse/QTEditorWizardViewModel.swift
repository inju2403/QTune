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
    private let fetchVersePrayerUseCase: FetchVersePrayerUseCase?
    private let fetchVerseExplanationUseCase: FetchVerseExplanationUseCase?

    // MARK: - Callbacks
    public var onSaveComplete: (() -> Void)?

    // MARK: - Init
    public init(
        commitQTUseCase: CommitQTUseCase,
        session: UserSession,
        fetchVersePrayerUseCase: FetchVersePrayerUseCase? = nil,
        fetchVerseExplanationUseCase: FetchVerseExplanationUseCase? = nil,
        initialState: QTEditorWizardState
    ) {
        self.commitQTUseCase = commitQTUseCase
        self.session = session
        self.fetchVersePrayerUseCase = fetchVersePrayerUseCase
        self.fetchVerseExplanationUseCase = fetchVerseExplanationUseCase
        self.state = initialState
        self.state.isPrayerAvailable = fetchVersePrayerUseCase != nil
        self.state.isExplanationAvailable = fetchVerseExplanationUseCase != nil
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
        case .updateFreeContent(let text):
            state.freeContent = text
        case .save:
            Task { await saveQT() }
        case .tapPrayerButton:
            // 이미 생성된 기도문이 있으면 바로 시트 열기
            if state.suggestedPrayer != nil {
                state.showPrayerSheet = true
            } else {
                // 없으면 생성 시작
                Task { await generatePrayer() }
            }
        case .dismissPrayerSheet:
            state.showPrayerSheet = false
        case .dismissPrayerError:
            state.prayerError = nil
        case .tapExplanationButton:
            // 이미 생성된 해설이 있으면 바로 시트 열기
            if !state.explKR.isEmpty {
                state.showExplanationSheet = true
            } else {
                // 없으면 생성 시작
                Task { await generateExplanation() }
            }
        case .dismissExplanationSheet:
            state.showExplanationSheet = false
        case .dismissExplanationError:
            state.explanationError = nil
        }
    }

    // MARK: - Helpers
    public var isFirstStep: Bool {
        switch state.template {
        case .soap:
            return state.soapStep == .observation
        case .acts:
            return state.actsStep == .adoration
        case .free:
            return true
        }
    }

    public var isLastStep: Bool {
        switch state.template {
        case .soap:
            return state.soapStep == .prayer
        case .acts:
            return state.actsStep == .supplication
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
        case .acts:
            return state.actsStep.rawValue
        case .free:
            return 0
        }
    }

    public var totalSteps: Int {
        switch state.template {
        case .soap:
            return SoapStep.allCases.count
        case .acts:
            return ACTSStep.allCases.count
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
        case .acts:
            if let next = ACTSStep(rawValue: state.actsStep.rawValue + 1) {
                state.actsStep = next
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
        case .acts:
            if let prev = ACTSStep(rawValue: state.actsStep.rawValue - 1) {
                state.actsStep = prev
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
            // 템플릿 문자열 결정
            let templateString: String
            switch state.template {
            case .soap:
                templateString = "SOAP"
            case .acts:
                templateString = "ACTS"
            case .free:
                templateString = "FREE"
            }

            // QuietTime 생성
            var qt = QuietTime(
                verse: state.verse,
                secondaryVerse: state.secondaryVerse,
                korean: state.explKR,
                rationale: state.rationale,
                suggestedPrayer: state.suggestedPrayer,
                date: Date(),
                status: .draft,
                template: templateString
            )

            // 템플릿별 필드 설정
            switch state.template {
            case .soap:
                qt.soapObservation = state.observation
                qt.soapApplication = state.application
                qt.soapPrayer = state.prayer
            case .acts:
                qt.actsAdoration = state.adoration
                qt.actsConfession = state.confession
                qt.actsThanksgiving = state.thanksgiving
                qt.actsSupplication = state.supplication
            case .free:
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

    // MARK: - Generate Prayer
    private func generatePrayer() async {
        guard let prayerUseCase = fetchVersePrayerUseCase else { return }
        guard !state.isPrayerLoading else { return }

        let englishText = state.verse.text
        let verseRef = state.verseRef

        state.isPrayerLoading = true
        state.prayerError = nil

        do {
            let prayer = try await prayerUseCase.execute(
                englishText: englishText,
                verseRef: verseRef
            )

            await MainActor.run {
                state.suggestedPrayer = prayer
                state.isPrayerLoading = false
                state.showPrayerSheet = true

                // 기도문 캐싱 알림 (템플릿 변경 후 재진입 시 재사용)
                NotificationCenter.default.post(
                    name: .prayerDidGenerate,
                    object: prayer
                )
            }
        } catch let error as DomainError {
            await MainActor.run {
                state.isPrayerLoading = false
                state.showPrayerSheet = true
                if case .rateLimited = error {
                    state.prayerError = "오늘 AI 기도문을 10번 모두 사용했어요. 내일 다시 시도해주세요."
                } else {
                    state.prayerError = "기도문을 가져오지 못했어요. 잠시 후 다시 시도해주세요."
                }
            }
        } catch {
            await MainActor.run {
                state.isPrayerLoading = false
                state.showPrayerSheet = true
                state.prayerError = "기도문을 가져오지 못했어요. 잠시 후 다시 시도해주세요."
            }
        }
    }

    // MARK: - Generate Explanation
    private func generateExplanation() async {
        guard let explanationUseCase = fetchVerseExplanationUseCase else { return }
        guard !state.isExplanationLoading else { return }

        let englishText = state.verse.text
        let verseRef = state.verseRef

        state.isExplanationLoading = true
        state.explanationError = nil

        do {
            let explanation = try await explanationUseCase.execute(
                englishText: englishText,
                verseRef: verseRef
            )

            await MainActor.run {
                state.explKR = explanation
                state.isExplanationLoading = false
                state.showExplanationSheet = true
            }
        } catch let error as DomainError {
            await MainActor.run {
                state.isExplanationLoading = false
                state.showExplanationSheet = true
                if case .rateLimited = error {
                    state.explanationError = "오늘 AI 해설을 10번 모두 사용했어요. 내일 다시 시도해주세요."
                } else {
                    state.explanationError = "해설을 가져오지 못했어요. 잠시 후 다시 시도해주세요."
                }
            }
        } catch {
            await MainActor.run {
                state.isExplanationLoading = false
                state.showExplanationSheet = true
                state.explanationError = "해설을 가져오지 못했어요. 잠시 후 다시 시도해주세요."
            }
        }
    }
}
