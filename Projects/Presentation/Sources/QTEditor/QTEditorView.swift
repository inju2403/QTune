//
//  QTEditorView.swift
//  Presentation
//
//  Created by 이승주 on 10/4/25.
//

import SwiftUI
import Domain

// MARK: - QTEditorView
/// QT 편집 화면 (기존 QT를 수정할 때 사용)
/// 이미 작성된 QT 내용을 수정하고 저장하는 화면
public struct QTEditorView: View {
    public let draft: QuietTime
    @State private var viewModel: QTEditorViewModel
    @Environment(\.dismiss) private var dismiss

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

            ScrollView(showsIndicators: false) {
                VStack(spacing: DS.Spacing.xl) {
                    // 말씀 카드 섹션 (읽기 전용)
                    verseCardSection()

                    // 편집 가능한 묵상/기도 섹션
                    if draft.template == "SOAP" {
                        soapEditSection()
                    } else {
                        actsEditSection()
                    }
                }
                .padding(DS.Spacing.l)
                .padding(.bottom, 80) // 저장 버튼 공간 확보
            }

            // 하단 저장 버튼
            VStack {
                Spacer()
                saveButton()
            }
        }
        .navigationTitle("QT 수정")
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture {
            self.endTextEditing()
        }
        .onAppear {
            viewModel.send(.loadQT(draft))
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
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation(Motion.appear) {
                                dismiss()
                            }
                        }
                    }
            }
        }
    }
}

// MARK: - Verse Card Section (읽기 전용)

private extension QTEditorView {
    @ViewBuilder
    func verseCardSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 영문 본문
            VerseCardView(title: "본문") {
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text(draft.verse.text)
                        .lineSpacing(4)
                        .textSelection(.enabled)

                    Text("\(draft.verse.translation) (Public Domain)")
                        .dsCaption()
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }

            // 한글 해설
            if let korean = draft.korean, !korean.isEmpty {
                VerseCardView(title: "해설") {
                    let lines = korean.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
                    if lines.count == 2 {
                        VStack(alignment: .leading, spacing: DS.Spacing.s) {
                            Text(String(lines[0]))
                                .dsBodyM(.semibold)
                                .foregroundStyle(DS.Color.gold)
                                .textSelection(.enabled)

                            Text(String(lines[1]))
                                .lineSpacing(4)
                                .textSelection(.enabled)
                        }
                    } else {
                        Text(korean)
                            .lineSpacing(4)
                            .textSelection(.enabled)
                    }
                }
            }

            // 이 말씀이 주어진 이유
            if let rationale = draft.rationale, !rationale.isEmpty {
                VerseCardView(title: "이 말씀이 주어진 이유") {
                    Text(rationale)
                        .lineSpacing(4)
                        .textSelection(.enabled)
                }
            }
        }
    }
}

// MARK: - SOAP Edit Section

private extension QTEditorView {
    @ViewBuilder
    func soapEditSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(icon: "square.and.pencil", title: "나의 묵상")

            EditableVerseCard(
                title: "Observation · 관찰",
                text: Binding(
                    get: { viewModel.state.soapTemplate.observation },
                    set: { viewModel.send(.updateSOAPObservation($0)) }
                ),
                placeholder: "말씀에서 눈에 들어오는 표현이나 문장을 적어보세요."
            )

            EditableVerseCard(
                title: "Application · 적용",
                text: Binding(
                    get: { viewModel.state.soapTemplate.application },
                    set: { viewModel.send(.updateSOAPApplication($0)) }
                ),
                placeholder: "이 말씀을 오늘 내 삶과 연결해보세요."
            )

            EditableVerseCard(
                title: "Prayer · 기도",
                text: Binding(
                    get: { viewModel.state.soapTemplate.prayer },
                    set: { viewModel.send(.updateSOAPPrayer($0)) }
                ),
                placeholder: "이 말씀을 통해 떠오른 마음이나 바람을 자유롭게 적어보세요."
            )
        }
    }
}

// MARK: - ACTS Edit Section

private extension QTEditorView {
    @ViewBuilder
    func actsEditSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(icon: "hands.sparkles", title: "나의 기도")

            EditableVerseCard(
                title: "Adoration · 경배",
                text: Binding(
                    get: { viewModel.state.actsTemplate.adoration },
                    set: { viewModel.send(.updateACTSAdoration($0)) }
                ),
                placeholder: "말씀을 통해 드러난 하나님의 성품을 묵상하며 경배를 드려보세요."
            )

            EditableVerseCard(
                title: "Confession · 고백",
                text: Binding(
                    get: { viewModel.state.actsTemplate.confession },
                    set: { viewModel.send(.updateACTSConfession($0)) }
                ),
                placeholder: "말씀 앞에서 회개하고 싶은 마음이 있나요?"
            )

            EditableVerseCard(
                title: "Thanksgiving · 감사",
                text: Binding(
                    get: { viewModel.state.actsTemplate.thanksgiving },
                    set: { viewModel.send(.updateACTSThanksgiving($0)) }
                ),
                placeholder: "하나님이 베푸신 구체적인 은혜와 축복에 감사를 표현해보세요."
            )

            EditableVerseCard(
                title: "Supplication · 간구",
                text: Binding(
                    get: { viewModel.state.actsTemplate.supplication },
                    set: { viewModel.send(.updateACTSSupplication($0)) }
                ),
                placeholder: "자신과 다른 사람들을 위해 하나님께 무엇을 간구하고 싶나요?"
            )
        }
    }
}

// MARK: - Editable Verse Card
/// QT 편집 화면 전용 편집 가능한 카드
/// 묵상/기도 내용을 수정할 수 있는 텍스트 편집 카드
struct EditableVerseCard: View {
    let title: String
    @Binding var text: String
    let placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            Text(title)
                .dsBodyM(.semibold)
                .foregroundStyle(DS.Color.textSecondary)

            // 회색 박스 안에 TextEditor (1탭 스타일, 대비 강화)
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 16, design: .rounded))
                        .foregroundStyle(Color(hex: "#B8B8B8"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                }

                TextEditor(text: $text)
                    .font(DS.Font.bodyL())
                    .foregroundStyle(Color(hex: "#1A1A1A"))
                    .frame(minHeight: 100)
                    .scrollContentBackground(.hidden)
                    .textInputAutocapitalization(.sentences)
                    .disableAutocorrection(false)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color(hex: "#F0F0F0"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.m)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.l))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.l)
                .stroke(Color(hex: "#E0E0E0"), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, y: 2)
    }
}

// MARK: - Save Button

private extension QTEditorView {
    @ViewBuilder
    func saveButton() -> some View {
        PrimaryButton(
            title: "저장",
            icon: ""
        ) {
            guard !viewModel.state.isSaving && !viewModel.state.showSaveSuccessToast else { return }
            Haptics.tap()
            viewModel.send(.saveQT(draft))
        }
        .padding(.horizontal, DS.Spacing.l)
        .padding(.vertical, DS.Spacing.s)
    }
}

// MARK: - Success Toast

private extension QTEditorView {
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
                    .dsBodyM(.semibold)
                    .foregroundStyle(DS.Color.textPrimary)
            }
        }
        .padding(.horizontal, DS.Spacing.l)
        .padding(.bottom, DS.Spacing.xxl)
    }
}
