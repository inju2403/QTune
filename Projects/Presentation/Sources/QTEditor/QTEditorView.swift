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
                    } else if draft.template == "FREE" {
                        freeEditSection()
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
                DSText.bodyM(draft.verse.text)
                    .textSelection(.enabled)
            }

            // 한글 해설
            if let korean = draft.korean, !korean.isEmpty {
                VerseCardView(title: "해설") {
                    let lines = korean.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
                    if lines.count == 2 {
                        VStack(alignment: .leading, spacing: DS.Spacing.s) {
                            DSText.bodyM(String(lines[0]), weight: .semibold)
                                .foregroundStyle(DS.Color.gold)
                                .textSelection(.enabled)

                            DSText.bodyM(String(lines[1]))
                                .textSelection(.enabled)
                        }
                    } else {
                        DSText.bodyM(korean)
                            .textSelection(.enabled)
                    }
                }
            }

            // 이 말씀이 주어진 이유
            if let rationale = draft.rationale, !rationale.isEmpty {
                VerseCardView(title: "이 말씀이 주어진 이유") {
                    DSText.bodyM(rationale)
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

// MARK: - Free Edit Section

private extension QTEditorView {
    @ViewBuilder
    func freeEditSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(icon: "square.and.pencil", title: "나의 묵상")

            EditableVerseCard(
                title: "자유 묵상",
                text: Binding(
                    get: { viewModel.state.freeTemplate.content },
                    set: { viewModel.send(.updateFreeContent($0)) }
                ),
                placeholder: "오늘 말씀을 통해 받은 은혜와 깨달음을 자유롭게 기록해보세요."
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
            DSText.bodyM(title, weight: .semibold)
                .foregroundStyle(DS.Color.textSecondary)

            // 회색 박스 안에 TextEditor (1탭 스타일, 대비 강화)
            DSTextEditor.editor(
                text: $text,
                placeholder: placeholder
            )
            .foregroundStyle(Color(hex: "#1A1A1A"))
            .frame(minHeight: 100)
            .scrollContentBackground(.hidden)
            .textInputAutocapitalization(.sentences)
            .disableAutocorrection(false)
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

                DSText.bodyM("기록이 저장되었습니다", weight: .semibold)
                    .foregroundStyle(DS.Color.textPrimary)
            }
        }
        .padding(.horizontal, DS.Spacing.l)
        .padding(.bottom, DS.Spacing.xxl)
    }
}
