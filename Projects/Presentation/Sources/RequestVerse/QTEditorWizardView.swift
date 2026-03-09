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

// MARK: - QTEditorWizardView
/// QT 작성 화면 (새로운 QT를 작성할 때 사용)
/// 말씀 추천을 받은 후 SOAP/Free 템플릿으로 묵상을 기록
public struct QTEditorWizardView: View {
    // MARK: - ViewModel
    @State private var viewModel: QTEditorWizardViewModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    @Environment(\.fontScale) private var fontScale

    // MARK: - Focus State
    @FocusState private var soapFocus: SoapStep?
    @FocusState private var freeFocus: Bool?

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
                                // 자유 묵상 (단일 필드)
                                SingleFieldCard(
                                    title: "자유 묵상",
                                    description: "오늘 말씀을 통해 받은 은혜와 깨달음을 자유롭게 기록해보세요.",
                                    placeholder: "오늘 말씀을 묵상하며 떠오르는 생각들을 자유롭게 적어보세요...",
                                    text: Binding(
                                        get: { viewModel.state.freeContent },
                                        set: { viewModel.send(.updateFreeContent($0)) }
                                    ),
                                    focused: $freeFocus,
                                    focusValue: true
                                )
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
                            }
                            // 자유 묵상은 단일 필드이므로 포커스 이동 불필요
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(viewModel.nextTitle)
                                .font(.system(size: 17 * fontScale.multiplier, weight: .bold))
                            if !viewModel.isLastStep {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12 * fontScale.multiplier, weight: .semibold))
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

            // 기도문 로딩 오버레이
            if viewModel.state.isPrayerLoading {
                QTuneCrossOverlay(message: "추천 기도문을 생성하는 중")
                    .transition(.opacity)
                    .zIndex(100)
            }

            // 해설 로딩 오버레이
            if viewModel.state.isExplanationLoading {
                QTuneCrossOverlay(message: "말씀의 해설을 준비하는 중")
                    .transition(.opacity)
                    .zIndex(100)
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
        .sheet(isPresented: Binding(
            get: { viewModel.state.showExplanationSheet },
            set: { if !$0 { viewModel.send(.dismissExplanationSheet) } }
        )) {
            explanationSheetView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(DS.Radius.xl)
                .presentationBackground(DS.Color.canvas)
        }
        .sheet(isPresented: Binding(
            get: { viewModel.state.showPrayerSheet },
            set: { if !$0 { viewModel.send(.dismissPrayerSheet) } }
        )) {
            prayerSheetView()
                .presentationDetents([.fraction(0.65), .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(DS.Radius.xl)
                .presentationBackground(DS.Color.canvas)
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
                    freeFocus = true
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

                DSText.bodyM("기록이 저장되었습니다", weight: .semibold)
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
                VStack(alignment: .leading, spacing: 20) {
                    // 성경 구절 참조
                    HStack(spacing: 6) {
                        Image(systemName: "book.closed.fill")
                            .foregroundStyle(DS.Color.gold)
                            .font(.system(size: 16 * fontScale.multiplier))
                        Text(viewModel.state.verseRef)
                            .font(.system(size: 16 * fontScale.multiplier, weight: .semibold, design: .rounded))
                            .foregroundStyle(DS.Color.deepCocoa)
                    }

                    DSText.verse(viewModel.state.verseEN.trimmingCharacters(in: .whitespacesAndNewlines), size: 16)
                        .foregroundStyle(DS.Color.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .padding(20)
                .background(DS.Color.canvas.opacity(0.9))
                .cornerRadius(DS.Radius.m)

                // 해설 + 기도문 버튼 (조건별 표시)
                if viewModel.state.isExplanationAvailable || viewModel.state.isPrayerAvailable {
                    HStack(spacing: 8) {
                        // 해설 버튼 (UseCase가 있을 때)
                        if viewModel.state.isExplanationAvailable {
                            Button {
                                Haptics.tap()
                                viewModel.send(.tapExplanationButton)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "book.fill")
                                        .font(.system(size: 12 * fontScale.multiplier, weight: .semibold))
                                    Text("해설")
                                        .font(.system(size: 14 * fontScale.multiplier, weight: .semibold, design: .rounded))
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
                        }

                        // 기도문 버튼 (UseCase가 있을 때만)
                        if viewModel.state.isPrayerAvailable {
                            Button {
                                Haptics.tap()
                                viewModel.send(.tapPrayerButton)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "hands.sparkles")
                                        .font(.system(size: 12 * fontScale.multiplier, weight: .semibold))
                                    Text("기도문")
                                        .font(.system(size: 14 * fontScale.multiplier, weight: .semibold, design: .rounded))
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
                        }
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

    // MARK: - Prayer Sheet

    @ViewBuilder
    private func explanationSheetView() -> some View {
        VStack(spacing: 0) {
            // 상단 아이콘과 타이틀
            VStack(spacing: 16) {
                // 아이콘
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [DS.Color.gold.opacity(0.2), DS.Color.mocha.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60 * fontScale.multiplier, height: 60 * fontScale.multiplier)

                    Image(systemName: "book.pages.fill")
                        .font(.system(size: 26 * fontScale.multiplier, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [DS.Color.mocha, DS.Color.gold],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                // 타이틀
                Text("해설")
                    .font(.system(size: 22 * fontScale.multiplier, weight: .bold, design: .rounded))
                    .foregroundStyle(DS.Color.mocha)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, DS.Spacing.xxl)
            .padding(.bottom, DS.Spacing.l)

            // 구분선
            Rectangle()
                .fill(DS.Color.gold.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal, DS.Spacing.xl)

            // 컨텐츠 영역
            ScrollView {
                VStack(spacing: DS.Spacing.l) {
                    // 에러 메시지
                    if let error = viewModel.state.explanationError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(.orange)

                            DSText.bodyM(error)
                                .foregroundStyle(DS.Color.textPrimary)
                                .multilineTextAlignment(.leading)

                            Spacer()
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.orange.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.orange.opacity(0.25), lineWidth: 1)
                                )
                        )
                    }

                    // 해설 내용
                    if !viewModel.state.explKR.isEmpty {
                        let lines = viewModel.state.explKR.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
                        if lines.count == 2 {
                            // 첫 줄은 강조
                            Text(String(lines[0]))
                                .font(.system(size: 19 * fontScale.multiplier, weight: .semibold, design: .rounded))
                                .foregroundStyle(DS.Color.gold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .textSelection(.enabled)

                            // 나머지 내용
                            DSText.bodyL(String(lines[1]))
                                .foregroundStyle(DS.Color.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .textSelection(.enabled)
                        } else {
                            DSText.bodyL(viewModel.state.explKR)
                                .foregroundStyle(DS.Color.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .textSelection(.enabled)
                        }
                    }
                }
                .padding(.horizontal, DS.Spacing.xl)
                .padding(.top, DS.Spacing.l)
                .padding(.bottom, DS.Spacing.xl)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }

    private func prayerSheetView() -> some View {
        VStack(spacing: 0) {
            // 상단 아이콘과 타이틀
            VStack(spacing: 16) {
                // 아이콘
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [DS.Color.gold.opacity(0.2), DS.Color.mocha.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60 * fontScale.multiplier, height: 60 * fontScale.multiplier)

                    Image(systemName: "hands.sparkles")
                        .font(.system(size: 26 * fontScale.multiplier, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [DS.Color.mocha, DS.Color.gold],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                // 타이틀
                Text("추천 기도문")
                    .font(.system(size: 22 * fontScale.multiplier, weight: .bold, design: .rounded))
                    .foregroundStyle(DS.Color.mocha)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, DS.Spacing.xxl)
            .padding(.bottom, DS.Spacing.l)

            // 구분선
            Rectangle()
                .fill(DS.Color.gold.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal, DS.Spacing.xl)

            // 컨텐츠 영역
            ScrollView {
                VStack(spacing: DS.Spacing.l) {
                    // 에러 메시지
                    if let error = viewModel.state.prayerError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(.orange)

                            DSText.bodyM(error)
                                .foregroundStyle(DS.Color.textPrimary)
                                .multilineTextAlignment(.leading)

                            Spacer()
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.orange.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.orange.opacity(0.25), lineWidth: 1)
                                )
                        )
                    }

                    // 기도문 결과
                    if let prayer = viewModel.state.suggestedPrayer {
                        DSText.bodyL(prayer)
                            .foregroundStyle(DS.Color.textPrimary)
                            .lineSpacing(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)
                    }
                }
                .padding(.horizontal, DS.Spacing.xl)
                .padding(.top, DS.Spacing.l)
                .padding(.bottom, DS.Spacing.xl)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
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

    @Environment(\.fontScale) private var fontScale

    private let maxLength = 500

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "pencil")
                    .foregroundStyle(DS.Color.gold)
                DSText.titleM(title, weight: .semibold)
                    .foregroundStyle(DS.Color.deepCocoa)

                Spacer()

                // 글자 수 카운터
                DSText.caption("\(text.count)/\(maxLength)")
                    .foregroundStyle(text.count > maxLength ? .red : DS.Color.textSecondary)
            }

            // Description
            DSText.bodyM(description)
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
                            .font(.system(size: 15 * fontScale.multiplier))
                            .foregroundStyle(DS.Color.placeholder)
                            .padding(.top, 20)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                    }

                    // Text 표시 (읽기 전용처럼 보이지만 편집 가능)
                    Text(text.isEmpty ? " " : text)
                        .font(.system(size: 15 * fontScale.multiplier))
                        .foregroundStyle(DS.Color.textPrimary)
                        .padding(16)
                        .frame(maxWidth: .infinity, minHeight: 180, alignment: .topLeading)
                        .opacity(0) // 투명하게 (높이 계산용)

                    // 실제 DSTextEditor (내부 스크롤 비활성화)
                    DSTextEditor.body(text: $text)
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
/// 해설 내용을 아름답게 표시하는 바텀시트
struct ExplanationSheetView: View {
    let explanation: String

    @Environment(\.fontScale) private var fontScale

    var body: some View {
        VStack(spacing: 0) {
                // 상단 아이콘과 타이틀
                VStack(spacing: 16) {
                    // 아이콘
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [DS.Color.gold.opacity(0.2), DS.Color.mocha.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60 * fontScale.multiplier, height: 60 * fontScale.multiplier)

                        Image(systemName: "book.pages.fill")
                            .font(.system(size: 26 * fontScale.multiplier, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [DS.Color.mocha, DS.Color.gold],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    // 타이틀
                    Text("해설")
                        .font(.system(size: 22 * fontScale.multiplier, weight: .bold, design: .rounded))
                        .foregroundStyle(DS.Color.mocha)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, DS.Spacing.xxl)
                .padding(.bottom, DS.Spacing.l)

                // 구분선
                Rectangle()
                    .fill(DS.Color.gold.opacity(0.2))
                    .frame(height: 1)
                    .padding(.horizontal, DS.Spacing.xl)

                // 해설 내용
                ScrollView {
                    VStack(alignment: .leading, spacing: DS.Spacing.l) {
                        let lines = explanation.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
                        if lines.count == 2 {
                            // 첫 줄은 강조
                            Text(String(lines[0]))
                                .font(.system(size: 19 * fontScale.multiplier, weight: .semibold, design: .rounded))
                                .foregroundStyle(DS.Color.gold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .textSelection(.enabled)

                            // 나머지 내용
                            DSText.bodyL(String(lines[1]))
                                .foregroundStyle(DS.Color.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .textSelection(.enabled)
                        } else {
                            DSText.bodyL(explanation)
                                .foregroundStyle(DS.Color.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .textSelection(.enabled)
                        }
                    }
                    .padding(.horizontal, DS.Spacing.xl)
                    .padding(.top, DS.Spacing.l)
                    .padding(.bottom, DS.Spacing.xl)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
    }
}
