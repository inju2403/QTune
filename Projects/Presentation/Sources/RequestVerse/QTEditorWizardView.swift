//
//  QTEditorWizardView.swift
//  Presentation
//
//  Created by 이승주 on 10/19/25.
//

import SwiftUI
import Domain

// MARK: - Step Enums

public enum SoapStep: Int, CaseIterable, Equatable {
    case observation
    case application
    case prayer
}

public enum ActsStep: Int, CaseIterable, Equatable {
    case adoration
    case confession
    case thanksgiving
    case supplication
}

// MARK: - QTEditorWizardView
/// QT 작성 화면 (새로운 QT를 작성할 때 사용)
/// 말씀 추천을 받은 후 SOAP/ACTS 템플릿으로 묵상을 기록
public struct QTEditorWizardView: View {
    // MARK: - ViewModel
    @State private var viewModel: QTEditorWizardViewModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss

    // MARK: - Focus State
    @FocusState private var soapFocus: SoapStep?
    @FocusState private var actsFocus: ActsStep?

    // MARK: - Sheet State
    @State private var showExplanationSheet = false
    @State private var sheetHeight: CGFloat = 200

    // MARK: - Init
    public init(viewModel: QTEditorWizardViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    // MARK: - Body
    public var body: some View {
        ZStack {
            CrossSunsetBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 전체 스크롤뷰 (말씀 + 해설 + 입력 카드)
                ScrollView {
                    VStack(spacing: 0) {
                        // 상단: 말씀 + 해설
                        verseHeaderContent()

                        // 중앙: 현재 스텝의 입력 카드
                        ZStack {
                            if viewModel.state.template == .soap {
                                StepPager(currentIndex: viewModel.currentStepIndex, total: viewModel.totalSteps) {
                                    switch viewModel.state.soapStep {
                                    case .observation:
                                        SingleFieldCard(
                                            title: "Observation · 관찰",
                                            description: "말씀에서 눈에 들어오는 표현이나 문장을 적어보세요.",
                                            placeholder: "어떤 단어나 문장이 마음에 남았나요?",
                                            text: Binding(
                                                get: { viewModel.state.observation },
                                                set: { viewModel.send(.updateObservation($0)) }
                                            ),
                                            focused: $soapFocus,
                                            focusValue: SoapStep.observation
                                        )
                                    case .application:
                                        SingleFieldCard(
                                            title: "Application · 적용",
                                            description: "이 말씀을 오늘 내 삶과 연결해보세요.",
                                            placeholder: "오늘 실천할 수 있는 작은 행동은 무엇일까요?",
                                            text: Binding(
                                                get: { viewModel.state.application },
                                                set: { viewModel.send(.updateApplication($0)) }
                                            ),
                                            focused: $soapFocus,
                                            focusValue: SoapStep.application
                                        )
                                    case .prayer:
                                        SingleFieldCard(
                                            title: "Prayer · 기도",
                                            description: "이 말씀을 통해 떠오른 마음이나 바람을 자유롭게 적어보세요.",
                                            placeholder: "어떤 생각이나 감정이 떠오르나요?",
                                            text: Binding(
                                                get: { viewModel.state.prayer },
                                                set: { viewModel.send(.updatePrayer($0)) }
                                            ),
                                            focused: $soapFocus,
                                            focusValue: SoapStep.prayer
                                        )
                                    }
                                }
                            } else {
                                StepPager(currentIndex: viewModel.currentStepIndex, total: viewModel.totalSteps) {
                                    switch viewModel.state.actsStep {
                                    case .adoration:
                                        SingleFieldCard(
                                            title: "Adoration · 경배",
                                            description: "말씀을 통해 드러난 하나님의 성품을 묵상하며 경배를 드려보세요.",
                                            placeholder: "이 말씀에서 경배하고 싶은 하나님의 성품을 적어보세요.",
                                            text: Binding(
                                                get: { viewModel.state.adoration },
                                                set: { viewModel.send(.updateAdoration($0)) }
                                            ),
                                            focused: $actsFocus,
                                            focusValue: ActsStep.adoration
                                        )
                                    case .confession:
                                        SingleFieldCard(
                                            title: "Confession · 회개",
                                            description: "말씀 앞에서 회개하고 싶은 마음이 있나요?",
                                            placeholder: "회개하고 싶은 것을 적어보세요.",
                                            text: Binding(
                                                get: { viewModel.state.confession },
                                                set: { viewModel.send(.updateConfession($0)) }
                                            ),
                                            focused: $actsFocus,
                                            focusValue: ActsStep.confession
                                        )
                                    case .thanksgiving:
                                        SingleFieldCard(
                                            title: "Thanksgiving · 감사",
                                            description: "하나님이 베푸신 구체적인 은혜와 축복에 감사를 표현해보세요.",
                                            placeholder: "감사하고 싶은 은혜는 무엇인가요?",
                                            text: Binding(
                                                get: { viewModel.state.thanksgiving },
                                                set: { viewModel.send(.updateThanksgiving($0)) }
                                            ),
                                            focused: $actsFocus,
                                            focusValue: ActsStep.thanksgiving
                                        )
                                    case .supplication:
                                        SingleFieldCard(
                                            title: "Supplication · 간구",
                                            description: "자신과 다른 사람들을 위해 하나님께 무엇을 간구하고 싶나요?",
                                            placeholder: "간구하고 싶은 기도 제목이 있나요?",
                                            text: Binding(
                                                get: { viewModel.state.supplication },
                                                set: { viewModel.send(.updateSupplication($0)) }
                                            ),
                                            focused: $actsFocus,
                                            focusValue: ActsStep.supplication
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 20)
                    }
                }

                // 하단: 이전/다음 버튼
                HStack(spacing: 12) {
                    // 이전 버튼 (첫 스텝이 아닐 때만 표시)
                    if !viewModel.isFirstStep {
                        Button {
                            Haptics.tap()
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                viewModel.send(.stepPrevious)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("이전")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundStyle(DS.Color.deepCocoa)
                            .frame(height: 50)
                            .padding(.horizontal, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(DS.Color.canvas.opacity(0.9))
                                    .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // 다음/저장 버튼 (확장)
                    Button {
                        guard viewModel.state.isCurrentStepValid else { return }
                        guard !viewModel.state.isSaving && !viewModel.state.showSaveSuccessToast else { return }

                        Haptics.tap()
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            viewModel.send(.stepNext)
                        }

                        // 다음 단계로 포커스 이동
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            if viewModel.state.template == .soap {
                                soapFocus = viewModel.state.soapStep
                            } else {
                                actsFocus = viewModel.state.actsStep
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(viewModel.nextTitle)
                                .font(.system(size: 17, weight: .bold))
                            if !viewModel.isLastStep {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    viewModel.state.isCurrentStepValid ?
                                    LinearGradient(
                                        colors: [DS.Color.gold.opacity(0.95), DS.Color.gold],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ) :
                                    LinearGradient(
                                        colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.4)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(
                                    color: viewModel.state.isCurrentStepValid ? DS.Color.gold.opacity(0.3) : Color.clear,
                                    radius: 8,
                                    y: 4
                                )
                        )
                    }
                    .animation(.easeInOut(duration: 0.2), value: viewModel.state.isCurrentStepValid)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    DS.Color.background.opacity(0.95)
                        .ignoresSafeArea(edges: .bottom)
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("QT 작성")
        .toolbar(.hidden, for: .tabBar)
        .onTapGesture {
            self.endTextEditing()
        }
        .alert("저장 실패", isPresented: Binding(
            get: { viewModel.state.showSaveErrorAlert },
            set: { _ in }
        )) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("저장에 실패했어요. 다시 시도해 주세요.")
        }
        .sheet(isPresented: $showExplanationSheet) {
            ExplanationSheetView(
                explanation: viewModel.state.explKR,
                sheetHeight: $sheetHeight
            )
            .presentationDetents([.height(sheetHeight)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(DS.Radius.xl)
            .presentationBackground(.white)
        }
        .overlay(alignment: .bottom) {
            if viewModel.state.showSaveSuccessToast {
                successToast()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(Motion.appear, value: viewModel.state.showSaveSuccessToast)
            }
        }
        .onChange(of: viewModel.state.showSaveSuccessToast) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    dismiss()
                }
            }
        }
        .onAppear {
            // 화면 진입 시 첫 번째 필드에 자동 포커스
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if viewModel.state.template == .soap {
                    soapFocus = .observation
                } else {
                    actsFocus = .adoration
                }
            }
        }
    }

    // MARK: - Success Toast

    @ViewBuilder
    private func successToast() -> some View {
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
                    .font(DS.Font.bodyM(.semibold))
                    .foregroundStyle(DS.Color.textPrimary)
            }
        }
        .padding(.horizontal, DS.Spacing.l)
        .padding(.bottom, DS.Spacing.xxl)
    }

    // MARK: - Subviews

    @ViewBuilder
    private func verseHeaderContent() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // 영어 말씀 (말씀 카드)
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 16) {
                    // 성경 구절 참조
                    HStack(spacing: 6) {
                        Image(systemName: "book.closed.fill")
                            .foregroundStyle(DS.Color.gold)
                            .font(.system(size: 14))
                        Text(viewModel.state.verseRef)
                            .font(DS.Font.caption(.semibold))
                            .foregroundStyle(DS.Color.deepCocoa)
                    }

                    Text(viewModel.state.verseEN.trimmingCharacters(in: .whitespacesAndNewlines))
                        .font(DS.Font.verse(16, .regular))
                        .foregroundStyle(DS.Color.textPrimary)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(20)
                .background(DS.Color.canvas.opacity(0.9))
                .cornerRadius(DS.Radius.m)

                // 해설 버튼 (한글 해설이 있을 때만 표시)
                if !viewModel.state.explKR.isEmpty {
                    Button {
                        Haptics.tap()
                        showExplanationSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "book.fill")
                                .font(.system(size: 12, weight: .semibold))
                            Text("해설")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [DS.Color.mocha, DS.Color.gold],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .overlay(
                            Capsule()
                                .stroke(DS.Color.gold.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: DS.Color.mocha.opacity(0.3), radius: 8, y: 2)
                    }
                    .padding(.top, 12)
                    .padding(.trailing, 12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 12)
        }
    }
}

// MARK: - StepPager (부드러운 페이드+스케일 전환)

struct StepPager<Content: View>: View {
    let currentIndex: Int
    let total: Int
    @ViewBuilder var content: () -> Content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        content()
            .id(currentIndex)
            .transition(
                reduceMotion
                    ? .opacity
                    : AnyTransition.asymmetric(
                        insertion: AnyTransition.opacity
                            .combined(with: .scale(scale: 0.95, anchor: .center))
                            .animation(.spring(response: 0.6, dampingFraction: 0.8)),
                        removal: AnyTransition.opacity
                            .combined(with: .scale(scale: 0.95, anchor: .center))
                            .animation(.spring(response: 0.5, dampingFraction: 0.85))
                    )
            )
    }
}

// MARK: - SingleFieldCard
/// QT 작성 화면 전용 단계별 입력 카드
/// SOAP/ACTS 템플릿에 따라 한 번에 하나씩 입력받는 카드
struct SingleFieldCard<FocusValue: Hashable>: View {
    let title: String
    let description: String
    let placeholder: String
    @Binding var text: String
    var focused: FocusState<FocusValue?>.Binding
    var focusValue: FocusValue

    private let maxLength = 500

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "pencil")
                    .foregroundStyle(DS.Color.gold)
                Text(title)
                    .font(DS.Font.titleM(.semibold))
                    .foregroundStyle(DS.Color.deepCocoa)

                Spacer()

                // 글자 수 카운터
                Text("\(text.count)/\(maxLength)")
                    .font(DS.Font.caption())
                    .foregroundStyle(text.count > maxLength ? .red : DS.Color.textSecondary)
            }

            // Description
            Text(description)
                .font(DS.Font.bodyM())
                .foregroundStyle(DS.Color.textSecondary)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 0) {
                // Placeholder 또는 TextEditor
                ZStack(alignment: .topLeading) {
                    // 배경
                    RoundedRectangle(cornerRadius: DS.Radius.s)
                        .fill(DS.Color.canvas)
                        .frame(minHeight: 180)

                    // Placeholder
                    if text.isEmpty {
                        Text(placeholder)
                            .font(DS.Font.bodyM())
                            .foregroundStyle(DS.Color.placeholder)
                            .padding(.top, 20)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                    }

                    // Text 표시 (읽기 전용처럼 보이지만 편집 가능)
                    Text(text.isEmpty ? " " : text)
                        .font(DS.Font.bodyM())
                        .foregroundStyle(DS.Color.textPrimary)
                        .padding(16)
                        .frame(maxWidth: .infinity, minHeight: 180, alignment: .topLeading)
                        .opacity(0) // 투명하게 (높이 계산용)

                    // 실제 TextEditor (내부 스크롤 비활성화)
                    TextEditor(text: $text)
                        .font(DS.Font.bodyM())
                        .foregroundStyle(DS.Color.textPrimary)
                        .padding(8)
                        .scrollContentBackground(.hidden)
                        .scrollDisabled(true)
                        .frame(minHeight: 180)
                        .background(Color.clear)
                        .focused(focused, equals: focusValue)
                        .onChange(of: text) { _, newValue in
                            // 500자 제한
                            if newValue.count > maxLength {
                                text = String(newValue.prefix(maxLength))
                            }
                        }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.m)
                .fill(DS.Color.background)
        )
    }
}


// MARK: - ExplanationSheetView
/// QT 작성 화면 전용 해설 바텀시트
/// 해설 내용만 간결하게 표시하는 동적 높이 바텀시트
struct ExplanationSheetView: View {
    let explanation: String
    @Binding var sheetHeight: CGFloat

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // 상단 핸들 영역
                HStack {
                    Text("해설")
                        .font(.system(size: 18, weight: .bold, design: .serif))
                        .foregroundStyle(DS.Color.mocha)

                    Spacer()
                }
                .padding(.horizontal, DS.Spacing.xl)
                .padding(.top, DS.Spacing.l)
                .padding(.bottom, DS.Spacing.m)

                // 해설 내용
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    let lines = explanation.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
                    if lines.count == 2 {
                        // 첫 줄은 강조
                        Text(String(lines[0]))
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(DS.Color.gold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)

                        // 나머지 내용
                        Text(String(lines[1]))
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundStyle(DS.Color.textPrimary)
                            .lineSpacing(5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text(explanation)
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundStyle(DS.Color.textPrimary)
                            .lineSpacing(5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, DS.Spacing.xl)
                .padding(.bottom, DS.Spacing.xl)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .onAppear {
                // 실제 컨텐츠 높이 측정 후 시트 높이 설정
                DispatchQueue.main.async {
                    let contentWidth = geometry.size.width - (DS.Spacing.xl * 2)
                    let estimatedHeight = calculateTextHeight(
                        text: explanation,
                        width: contentWidth,
                        font: .systemFont(ofSize: 15)
                    )
                    // title(18) + top padding(16) + bottom padding(12) + content + bottom padding(24) + extra space(40)
                    let totalHeight = 18 + 16 + 12 + estimatedHeight + 24 + 40
                    sheetHeight = min(max(totalHeight, 180), UIScreen.main.bounds.height * 0.7)
                }
            }
        }
    }

    private func calculateTextHeight(text: String, width: CGFloat, font: UIFont) -> CGFloat {
        let lines = text.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
        var totalHeight: CGFloat = 0

        if lines.count == 2 {
            // 첫 줄 (강조)
            let firstFont = UIFont.systemFont(ofSize: 17, weight: .semibold)
            let firstHeight = String(lines[0]).boundingRect(
                with: CGSize(width: width, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: firstFont],
                context: nil
            ).height

            // 두 번째 줄 (본문)
            let secondHeight = String(lines[1]).boundingRect(
                with: CGSize(width: width, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: font],
                context: nil
            ).height

            totalHeight = firstHeight + DS.Spacing.m + secondHeight + (5 * 2) // lineSpacing 고려
        } else {
            totalHeight = text.boundingRect(
                with: CGSize(width: width, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: font],
                context: nil
            ).height + (5 * 2) // lineSpacing 고려
        }

        return totalHeight
    }
}

// MARK: - ContentHeightKey
/// 동적 높이 계산을 위한 PreferenceKey
struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
