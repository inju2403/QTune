//
//  QTEditorView.swift
//  Presentation
//
//  Created by 이승주 on 10/4/25.
//

import SwiftUI
import Domain

public struct QTEditorView: View {
    public let draft: QuietTime
    @StateObject private var viewModel: QTEditorViewModel
    @Environment(\.dismiss) private var dismiss

    public init(
        draft: QuietTime,
        viewModel: QTEditorViewModel
    ) {
        self.draft = draft
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        ZStack {
            CrossSunsetBackground()

            ScrollView {
                VStack(spacing: DS.Spacing.xl) {
                    // 상단 고정 카드 (읽기 전용)
                    verseCardSection()

                    // 템플릿 선택 토글
                    templateToggleSection()

                    // 템플릿별 입력 섹션 (선택된 템플릿만 표시)
                    if viewModel.selectedTemplate == .soap {
                        soapTemplateSections()
                    } else {
                        actsTemplateSections()
                    }

                    // 저장 버튼
                    saveButtonSection()
                }
                .padding(DS.Spacing.l)
            }
        }
        .navigationTitle("QT 작성")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadQT(draft)
        }
        .alert("저장 실패", isPresented: $viewModel.showSaveErrorAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("저장에 실패했어요. 다시 시도해 주세요.")
        }
        .overlay(alignment: .bottom) {
            if viewModel.showSaveSuccessToast {
                successToast()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(Motion.appear, value: viewModel.showSaveSuccessToast)
                    .onAppear {
                        Haptics.success()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation(Motion.appear) {
                                viewModel.showSaveSuccessToast = false
                                dismiss()
                            }
                        }
                    }
            }
        }
    }
}

// MARK: - Subviews
private extension QTEditorView {
    // 템플릿 선택 토글
    @ViewBuilder
    func templateToggleSection() -> some View {
        HStack(spacing: DS.Spacing.m) {
            // S.O.A.P 버튼
            Button {
                Haptics.tap()
                withAnimation(Motion.appear) {
                    viewModel.switchTemplate(to: .soap)
                }
            } label: {
                HStack(spacing: DS.Spacing.s) {
                    Image(systemName: "square.and.pencil")
                        .font(DS.Font.bodyL())
                    Text("S.O.A.P")
                        .font(DS.Font.bodyL(.semibold))
                }
                .foregroundStyle(viewModel.selectedTemplate == .soap ? DS.Color.gold : DS.Color.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Spacing.m)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.m)
                        .fill(viewModel.selectedTemplate == .soap ? DS.Color.gold.opacity(0.15) : DS.Color.canvas)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.m)
                        .stroke(viewModel.selectedTemplate == .soap ? DS.Color.gold : DS.Color.divider, lineWidth: 2)
                )
            }

            // A.C.T.S 버튼
            Button {
                Haptics.tap()
                withAnimation(Motion.appear) {
                    viewModel.switchTemplate(to: .acts)
                }
            } label: {
                HStack(spacing: DS.Spacing.s) {
                    Image(systemName: "hands.sparkles")
                        .font(DS.Font.bodyL())
                    Text("A.C.T.S")
                        .font(DS.Font.bodyL(.semibold))
                }
                .foregroundStyle(viewModel.selectedTemplate == .acts ? DS.Color.gold : DS.Color.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Spacing.m)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.m)
                        .fill(viewModel.selectedTemplate == .acts ? DS.Color.gold.opacity(0.15) : DS.Color.canvas)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.m)
                        .stroke(viewModel.selectedTemplate == .acts ? DS.Color.gold : DS.Color.divider, lineWidth: 2)
                )
            }
        }
    }

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

    // S.O.A.P 템플릿 섹션들
    @ViewBuilder
    func soapTemplateSections() -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xl) {
            SectionHeader(icon: "square.and.pencil", title: "나의 묵상")

            // O: Observation
            inputSection(
                icon: "eye",
                title: "Observation",
                subtitle: "관찰",
                text: $viewModel.soapTemplate.observation,
                placeholder: viewModel.soapTemplate.observationPlaceholder,
                minHeight: 100,
                onChanged: viewModel.updateSOAPObservation
            )

            // A: Application
            inputSection(
                icon: "arrow.right.circle",
                title: "Application",
                subtitle: "적용",
                text: $viewModel.soapTemplate.application,
                placeholder: viewModel.soapTemplate.applicationPlaceholder,
                minHeight: 100,
                onChanged: viewModel.updateSOAPApplication
            )

            // P: Prayer
            inputSection(
                icon: "hands.sparkles",
                title: "Prayer",
                subtitle: "기도",
                text: $viewModel.soapTemplate.prayer,
                placeholder: viewModel.soapTemplate.prayerPlaceholder,
                minHeight: 100,
                onChanged: viewModel.updateSOAPPrayer
            )
        }
    }

    // A.C.T.S 템플릿 섹션들
    @ViewBuilder
    func actsTemplateSections() -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xl) {
            SectionHeader(icon: "hands.sparkles", title: "나의 기도")

            // A: Adoration
            inputSection(
                icon: "sparkles",
                title: "Adoration",
                subtitle: "경배",
                text: $viewModel.actsTemplate.adoration,
                placeholder: viewModel.actsTemplate.adorationPlaceholder,
                minHeight: 100,
                onChanged: viewModel.updateACTSAdoration
            )

            // C: Confession
            inputSection(
                icon: "heart",
                title: "Confession",
                subtitle: "고백",
                text: $viewModel.actsTemplate.confession,
                placeholder: viewModel.actsTemplate.confessionPlaceholder,
                minHeight: 100,
                onChanged: viewModel.updateACTSConfession
            )

            // T: Thanksgiving
            inputSection(
                icon: "leaf",
                title: "Thanksgiving",
                subtitle: "감사",
                text: $viewModel.actsTemplate.thanksgiving,
                placeholder: viewModel.actsTemplate.thanksgivingPlaceholder,
                minHeight: 100,
                onChanged: viewModel.updateACTSThanksgiving
            )

            // S: Supplication
            inputSection(
                icon: "hands.and.sparkles",
                title: "Supplication",
                subtitle: "간구",
                text: $viewModel.actsTemplate.supplication,
                placeholder: viewModel.actsTemplate.supplicationPlaceholder,
                minHeight: 100,
                onChanged: viewModel.updateACTSSupplication
            )
        }
    }

    // 입력 섹션 (헤더 + 카드 + 카운터)
    @ViewBuilder
    func inputSection(
        icon: String,
        title: String,
        subtitle: String,
        text: Binding<String>,
        placeholder: String,
        minHeight: CGFloat,
        onChanged: @escaping (String) -> Void
    ) -> some View {
        SoftCard {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                // 헤더
                HStack(spacing: DS.Spacing.s) {
                    Image(systemName: icon)
                        .foregroundStyle(DS.Color.gold)
                        .font(DS.Font.bodyL())

                    Text(title)
                        .font(DS.Font.bodyL(.semibold))
                        .foregroundStyle(DS.Color.textPrimary)

                    Text("·")
                        .foregroundStyle(DS.Color.textSecondary)

                    Text(subtitle)
                        .font(DS.Font.bodyM())
                        .foregroundStyle(DS.Color.textSecondary)

                    Spacer()

                    // 글자수 카운터
                    Text(viewModel.characterCount(for: text.wrappedValue))
                        .font(DS.Font.caption())
                        .foregroundStyle(viewModel.isOverLimit(for: text.wrappedValue) ? .red : DS.Color.textSecondary)
                }

                // 입력 필드
                inputField(
                    text: text,
                    placeholder: placeholder,
                    minHeight: minHeight,
                    onChanged: onChanged
                )
            }
        }
    }

    // 입력 필드 공통 컴포넌트
    @ViewBuilder
    func inputField(
        text: Binding<String>,
        placeholder: String,
        minHeight: CGFloat,
        onChanged: @escaping (String) -> Void
    ) -> some View {
        ZStack(alignment: .topLeading) {
            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .font(DS.Font.bodyM())
                    .foregroundStyle(DS.Color.textSecondary.opacity(0.4))
                    .padding(.horizontal, DS.Spacing.xs)
                    .padding(.vertical, DS.Spacing.s)
            }

            TextEditor(text: text)
            .font(DS.Font.bodyM())
            .foregroundStyle(DS.Color.textPrimary)
            .frame(minHeight: minHeight)
            .scrollContentBackground(.hidden)
            .textInputAutocapitalization(.sentences)
            .disableAutocorrection(false)
        }
        .padding(DS.Spacing.s)
        .background(DS.Color.background)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.s))
    }

    // 저장 버튼 섹션
    @ViewBuilder
    func saveButtonSection() -> some View {
        PrimaryButton(title: "저장하기", icon: "checkmark.circle.fill") {
            Haptics.tap()
            Task { @MainActor in
                await viewModel.saveQT(draft: draft)
            }
        }
        .padding(.top, DS.Spacing.l)
        .padding(.bottom, DS.Spacing.xxl)
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
