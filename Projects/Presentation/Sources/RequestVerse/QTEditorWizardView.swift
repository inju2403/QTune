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

public struct QTEditorWizardView: View {
    // MARK: - ViewModel
    @State private var viewModel: QTEditorWizardViewModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss

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
                        // 상단: 영어 말씀 + 해설
                        verseHeaderContent()

                        // 중앙: 현재 스텝의 입력 카드
                        ZStack {
                            if viewModel.state.template == .soap {
                                StepPager(currentIndex: viewModel.currentStepIndex, total: viewModel.totalSteps) {
                                    switch viewModel.state.soapStep {
                                    case .observation:
                                        SingleFieldCard(
                                            title: "Observation · 관찰",
                                            placeholder: "무엇이 보이나요?",
                                            text: Binding(
                                                get: { viewModel.state.observation },
                                                set: { viewModel.send(.updateObservation($0)) }
                                            )
                                        )
                                    case .application:
                                        SingleFieldCard(
                                            title: "Application · 적용",
                                            placeholder: "어떻게 살기로 결단하나요?",
                                            text: Binding(
                                                get: { viewModel.state.application },
                                                set: { viewModel.send(.updateApplication($0)) }
                                            )
                                        )
                                    case .prayer:
                                        SingleFieldCard(
                                            title: "Prayer · 기도",
                                            placeholder: "이 말씀으로 드리는 기도",
                                            text: Binding(
                                                get: { viewModel.state.prayer },
                                                set: { viewModel.send(.updatePrayer($0)) }
                                            )
                                        )
                                    }
                                }
                            } else {
                                StepPager(currentIndex: viewModel.currentStepIndex, total: viewModel.totalSteps) {
                                    switch viewModel.state.actsStep {
                                    case .adoration:
                                        SingleFieldCard(
                                            title: "Adoration · 찬양",
                                            placeholder: "주님은 어떤 분이신가요?",
                                            text: Binding(
                                                get: { viewModel.state.adoration },
                                                set: { viewModel.send(.updateAdoration($0)) }
                                            )
                                        )
                                    case .confession:
                                        SingleFieldCard(
                                            title: "Confession · 고백",
                                            placeholder: "회개할 것은 무엇인가요?",
                                            text: Binding(
                                                get: { viewModel.state.confession },
                                                set: { viewModel.send(.updateConfession($0)) }
                                            )
                                        )
                                    case .thanksgiving:
                                        SingleFieldCard(
                                            title: "Thanksgiving · 감사",
                                            placeholder: "감사 제목을 적어보세요",
                                            text: Binding(
                                                get: { viewModel.state.thanksgiving },
                                                set: { viewModel.send(.updateThanksgiving($0)) }
                                            )
                                        )
                                    case .supplication:
                                        SingleFieldCard(
                                            title: "Supplication · 간구",
                                            placeholder: "구하는 바를 적어보세요",
                                            text: Binding(
                                                get: { viewModel.state.supplication },
                                                set: { viewModel.send(.updateSupplication($0)) }
                                            )
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
                        Haptics.tap()
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            viewModel.send(.stepNext)
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
                                    LinearGradient(
                                        colors: [DS.Color.mocha, DS.Color.deepCocoa],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: DS.Color.mocha.opacity(0.3), radius: 8, y: 4)
                        )
                    }
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
            }
        }
        .onChange(of: viewModel.state.showSaveSuccessToast) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    dismiss()
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
                    .font(DS.Font.bodyL(.semibold))
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
            // 영어 말씀
            VStack(alignment: .leading, spacing: 12) {
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
                    .font(DS.Font.verse(18, .regular))
                    .foregroundStyle(DS.Color.textPrimary)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
            .background(DS.Color.canvas.opacity(0.9))
            .cornerRadius(DS.Radius.m)
            .padding(.horizontal, 20)
            .padding(.top, 12)

            // 한글 해설 (영구 표시)
            if !viewModel.state.explKR.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(DS.Color.gold)
                            .font(.system(size: 12))
                        Text("해설")
                            .font(DS.Font.caption(.semibold))
                            .foregroundStyle(DS.Color.deepCocoa)
                    }

                    Text(viewModel.state.explKR.trimmingCharacters(in: .whitespacesAndNewlines))
                        .font(DS.Font.bodyM())
                        .foregroundStyle(DS.Color.textPrimary)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(16)
                .background(DS.Color.canvas.opacity(0.9))
                .cornerRadius(DS.Radius.m)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 12)
            } else {
                Spacer()
                    .frame(height: 12)
            }
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

// MARK: - SingleFieldCard (단일 입력 카드)

struct SingleFieldCard: View {
    let title: String
    let placeholder: String
    @Binding var text: String

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

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(DS.Font.bodyM())
                        .foregroundStyle(DS.Color.placeholder)
                        .padding(.top, 12)
                        .padding(.horizontal, 12)
                }

                TextEditor(text: $text)
                    .font(DS.Font.bodyM())
                    .foregroundStyle(DS.Color.textPrimary)
                    .frame(minHeight: 180)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.s)
                            .fill(DS.Color.canvas)
                    )
                    .onChange(of: text) { _, newValue in
                        // 500자 제한
                        if newValue.count > maxLength {
                            text = String(newValue.prefix(maxLength))
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
