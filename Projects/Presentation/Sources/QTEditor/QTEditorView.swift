//
//  QTEditorView.swift
//  Presentation
//
//  Created by 이승주 on 10/4/25.
//

import SwiftUI
import Domain

// MARK: - Flow Step

enum QTFlowStep: Equatable {
    case templateSelection

    // SOAP steps
    case observation
    case application
    case prayer

    // ACTS steps
    case adoration
    case confession
    case thanksgiving
    case supplication
}

// MARK: - QTEditorView

public struct QTEditorView: View {
    public let draft: QuietTime
    @State private var viewModel: QTEditorViewModel
    @Environment(\.dismiss) private var dismiss

    // Flow state (UI 로컬 상태)
    @State private var currentStep: QTFlowStep = .templateSelection
    @State private var selectedTemplateType: QTTemplateType? = nil

    public init(
        draft: QuietTime,
        viewModel: QTEditorViewModel
    ) {
        self.draft = draft
        _viewModel = State(wrappedValue: viewModel)
    }

    public var body: some View {
        ZStack {
            CrossSunsetBackground()

            VStack(spacing: 0) {
                // 상단 고정: 말씀 블록
                ScrollView(showsIndicators: false) {
                    verseCardSection()
                        .padding(DS.Spacing.l)
                }
                .frame(maxHeight: 300)

                Divider()
                    .background(DS.Color.divider)

                // 중앙: 현재 단계 표시
                ZStack {
                    currentStepView()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // 하단 고정: 다음/완료 버튼
                bottomButtonSection()
            }
        }
        .navigationTitle("QT 작성")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.send(.loadQT(draft))
            // 기존에 템플릿이 선택되어 있으면 해당 템플릿의 첫 단계로 이동
            if viewModel.state.selectedTemplate == .soap {
                selectedTemplateType = .soap
                currentStep = .observation
            } else if viewModel.state.selectedTemplate == .acts {
                selectedTemplateType = .acts
                currentStep = .adoration
            }
        }
        .alert("저장 실패", isPresented: Binding(
            get: { viewModel.state.showSaveErrorAlert },
            set: { _ in }
        )) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("저장에 실패했어요. 다시 시도해 주세요.")
        }
        .overlay(alignment: .bottom) {
            if viewModel.state.showSaveSuccessToast {
                successToast()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(Motion.appear, value: viewModel.state.showSaveSuccessToast)
                    .onAppear {
                        Haptics.success()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation(Motion.appear) {
                                dismiss()
                            }
                        }
                    }
            }
        }
    }
}

// MARK: - Current Step View

private extension QTEditorView {
    @ViewBuilder
    func currentStepView() -> some View {
        Group {
            switch currentStep {
            case .templateSelection:
                templateSelectionView()
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

            case .observation:
                stepInputView(
                    icon: "eye",
                    title: "Observation",
                    subtitle: "관찰",
                    text: viewModel.state.soapTemplate.observation,
                    placeholder: viewModel.state.soapTemplate.observationPlaceholder,
                    onChanged: { viewModel.send(.updateSOAPObservation($0)) }
                )
                .transition(slideTransition)

            case .application:
                stepInputView(
                    icon: "arrow.right.circle",
                    title: "Application",
                    subtitle: "적용",
                    text: viewModel.state.soapTemplate.application,
                    placeholder: viewModel.state.soapTemplate.applicationPlaceholder,
                    onChanged: { viewModel.send(.updateSOAPApplication($0)) }
                )
                .transition(slideTransition)

            case .prayer:
                stepInputView(
                    icon: "hands.sparkles",
                    title: "Prayer",
                    subtitle: "기도",
                    text: viewModel.state.soapTemplate.prayer,
                    placeholder: viewModel.state.soapTemplate.prayerPlaceholder,
                    onChanged: { viewModel.send(.updateSOAPPrayer($0)) }
                )
                .transition(slideTransition)

            case .adoration:
                stepInputView(
                    icon: "sparkles",
                    title: "Adoration",
                    subtitle: "경배",
                    text: viewModel.state.actsTemplate.adoration,
                    placeholder: viewModel.state.actsTemplate.adorationPlaceholder,
                    onChanged: { viewModel.send(.updateACTSAdoration($0)) }
                )
                .transition(slideTransition)

            case .confession:
                stepInputView(
                    icon: "heart",
                    title: "Confession",
                    subtitle: "고백",
                    text: viewModel.state.actsTemplate.confession,
                    placeholder: viewModel.state.actsTemplate.confessionPlaceholder,
                    onChanged: { viewModel.send(.updateACTSConfession($0)) }
                )
                .transition(slideTransition)

            case .thanksgiving:
                stepInputView(
                    icon: "leaf",
                    title: "Thanksgiving",
                    subtitle: "감사",
                    text: viewModel.state.actsTemplate.thanksgiving,
                    placeholder: viewModel.state.actsTemplate.thanksgivingPlaceholder,
                    onChanged: { viewModel.send(.updateACTSThanksgiving($0)) }
                )
                .transition(slideTransition)

            case .supplication:
                stepInputView(
                    icon: "hands.and.sparkles",
                    title: "Supplication",
                    subtitle: "간구",
                    text: viewModel.state.actsTemplate.supplication,
                    placeholder: viewModel.state.actsTemplate.supplicationPlaceholder,
                    onChanged: { viewModel.send(.updateACTSSupplication($0)) }
                )
                .transition(slideTransition)
            }
        }
    }

    var slideTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
}

// MARK: - Template Selection View

private extension QTEditorView {
    @ViewBuilder
    func templateSelectionView() -> some View {
        VStack(spacing: DS.Spacing.xl) {
            Spacer()

            VStack(spacing: DS.Spacing.m) {
                Image(systemName: "book.pages")
                    .font(.system(size: 48))
                    .foregroundStyle(DS.Color.gold)

                Text("묵상 템플릿 선택")
                    .font(DS.Font.titleL(.bold))
                    .foregroundStyle(DS.Color.deepCocoa)

                Text("어떤 방식으로 묵상하시겠어요?")
                    .font(DS.Font.bodyM())
                    .foregroundStyle(DS.Color.textSecondary)
            }
            .padding(.bottom, DS.Spacing.xl)

            VStack(spacing: DS.Spacing.m) {
                // SOAP 선택 카드
                Button {
                    Haptics.tap()
                    withAnimation(.easeInOut(duration: 0.35)) {
                        selectedTemplateType = .soap
                        viewModel.send(.switchTemplate(.soap))
                        currentStep = .observation
                    }
                } label: {
                    templateCard(
                        icon: "square.and.pencil",
                        title: "S.O.A.P",
                        subtitle: "Scripture · Observation · Application · Prayer",
                        description: "성경 구절을 관찰하고 적용하며 기도하는 방식"
                    )
                }

                // ACTS 선택 카드
                Button {
                    Haptics.tap()
                    withAnimation(.easeInOut(duration: 0.35)) {
                        selectedTemplateType = .acts
                        viewModel.send(.switchTemplate(.acts))
                        currentStep = .adoration
                    }
                } label: {
                    templateCard(
                        icon: "hands.sparkles",
                        title: "A.C.T.S",
                        subtitle: "Adoration · Confession · Thanksgiving · Supplication",
                        description: "찬양, 고백, 감사, 간구로 기도하는 방식"
                    )
                }
            }

            Spacer()
        }
        .padding(DS.Spacing.l)
    }

    @ViewBuilder
    func templateCard(icon: String, title: String, subtitle: String, description: String) -> some View {
        SoftCard {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                HStack(spacing: DS.Spacing.m) {
                    Image(systemName: icon)
                        .font(.system(size: 32))
                        .foregroundStyle(DS.Color.gold)

                    VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                        Text(title)
                            .font(DS.Font.titleM(.bold))
                            .foregroundStyle(DS.Color.deepCocoa)

                        Text(subtitle)
                            .font(DS.Font.caption())
                            .foregroundStyle(DS.Color.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(DS.Font.bodyL())
                        .foregroundStyle(DS.Color.textSecondary)
                }

                Text(description)
                    .font(DS.Font.bodyM())
                    .foregroundStyle(DS.Color.textSecondary)
                    .lineSpacing(4)
            }
            .padding(DS.Spacing.l)
        }
    }
}

// MARK: - Step Input View

private extension QTEditorView {
    @ViewBuilder
    func stepInputView(
        icon: String,
        title: String,
        subtitle: String,
        text: String,
        placeholder: String,
        onChanged: @escaping (String) -> Void
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.l) {
                // 단계 헤더
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    HStack(spacing: DS.Spacing.s) {
                        Image(systemName: icon)
                            .foregroundStyle(DS.Color.gold)
                            .font(.system(size: 28))

                        Text(title)
                            .font(DS.Font.titleL(.bold))
                            .foregroundStyle(DS.Color.deepCocoa)
                    }

                    Text(subtitle)
                        .font(DS.Font.bodyL())
                        .foregroundStyle(DS.Color.textSecondary)
                }
                .padding(.bottom, DS.Spacing.m)

                // 입력 필드
                SoftCard {
                    VStack(alignment: .leading, spacing: DS.Spacing.m) {
                        HStack {
                            Spacer()
                            Text(viewModel.characterCount(for: text))
                                .font(DS.Font.caption())
                                .foregroundStyle(viewModel.isOverLimit(for: text) ? .red : DS.Color.textSecondary)
                        }

                        ZStack(alignment: .topLeading) {
                            if text.isEmpty {
                                Text(placeholder)
                                    .font(DS.Font.bodyM())
                                    .foregroundStyle(DS.Color.textSecondary.opacity(0.4))
                                    .padding(.horizontal, DS.Spacing.xs)
                                    .padding(.vertical, DS.Spacing.s)
                            }

                            TextEditor(text: Binding(
                                get: { text },
                                set: { onChanged($0) }
                            ))
                                .font(DS.Font.bodyM())
                                .foregroundStyle(DS.Color.textPrimary)
                                .frame(minHeight: 200)
                                .scrollContentBackground(.hidden)
                                .textInputAutocapitalization(.sentences)
                                .disableAutocorrection(false)
                        }
                        .padding(DS.Spacing.s)
                        .background(DS.Color.background)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.s))
                    }
                }
            }
            .padding(DS.Spacing.l)
        }
    }
}

// MARK: - Bottom Button Section

private extension QTEditorView {
    @ViewBuilder
    func bottomButtonSection() -> some View {
        VStack(spacing: 0) {
            Divider()
                .background(DS.Color.divider)

            PrimaryButton(
                title: isLastStep ? "완료" : "다음",
                icon: isLastStep ? "checkmark.circle.fill" : "arrow.right.circle.fill"
            ) {
                Haptics.tap()
                handleNextButton()
            }
            .padding(DS.Spacing.l)
            .background(DS.Color.canvas)
        }
    }

    var isLastStep: Bool {
        if let template = selectedTemplateType {
            switch template {
            case .soap:
                return currentStep == .prayer
            case .acts:
                return currentStep == .supplication
            }
        }
        return false
    }

    func handleNextButton() {
        if isLastStep {
            // 완료: 저장 처리
            viewModel.send(.saveQT(draft))
        } else {
            // 다음 단계로 이동
            withAnimation(.easeInOut(duration: 0.35)) {
                currentStep = nextStep()
            }
        }
    }

    func nextStep() -> QTFlowStep {
        guard let template = selectedTemplateType else {
            return .templateSelection
        }

        switch template {
        case .soap:
            switch currentStep {
            case .observation:
                return .application
            case .application:
                return .prayer
            default:
                return .observation
            }
        case .acts:
            switch currentStep {
            case .adoration:
                return .confession
            case .confession:
                return .thanksgiving
            case .thanksgiving:
                return .supplication
            default:
                return .adoration
            }
        }
    }
}

// MARK: - Subviews

private extension QTEditorView {
    // 상단 말씀 카드 (읽기 전용)
    @ViewBuilder
    func verseCardSection() -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.l) {
            SectionHeader(icon: "book.closed.fill", title: "오늘의 말씀")

            // 구절 제목
            HStack {
                Image(systemName: "book.closed.fill")
                    .foregroundStyle(DS.Color.gold)
                Text(draft.verse.id)
                    .font(DS.Font.titleM(.semibold))
                    .foregroundStyle(DS.Color.deepCocoa)
            }
            .padding(.horizontal, DS.Spacing.m)

            // 영문 본문
            VerseCardView(title: "본문") {
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text(draft.verse.text)
                        .lineSpacing(4)

                    Text("\(draft.verse.translation) (Public Domain)")
                        .font(DS.Font.caption())
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }

            // 한글 해설 (있는 경우)
            if let korean = draft.korean, !korean.isEmpty {
                VerseCardView(title: "해설") {
                    let lines = korean.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
                    if lines.count == 2 {
                        VStack(alignment: .leading, spacing: DS.Spacing.s) {
                            Text(String(lines[0]))
                                .font(DS.Font.bodyL(.semibold))
                                .foregroundStyle(DS.Color.gold)

                            Text(String(lines[1]))
                                .lineSpacing(4)
                        }
                    } else {
                        Text(korean)
                            .lineSpacing(4)
                    }
                }
            }

            // 추천 이유 (있는 경우)
            if let rationale = draft.rationale, !rationale.isEmpty {
                VerseCardView(title: "추천 이유") {
                    Text(rationale)
                        .lineSpacing(4)
                }
            }
        }
    }

    // 성공 토스트
    @ViewBuilder
    func successToast() -> some View {
        SoftCard {
            HStack(spacing: DS.Spacing.m) {
                ZStack {
                    Circle()
                        .fill(DS.Color.success.opacity(0.2))
                        .frame(width: 32, height: 32)
                        .blur(radius: 6)

                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(DS.Color.success)
                        .font(DS.Font.titleM())
                }

                Text("기록이 저장되었습니다")
                    .font(DS.Font.bodyL(.semibold))
                    .foregroundStyle(DS.Color.textPrimary)
            }
        }
        .padding(.horizontal, DS.Spacing.l)
        .padding(.bottom, DS.Spacing.xxl)
    }
}
