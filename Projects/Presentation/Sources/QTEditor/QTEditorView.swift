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
        Form {
            // 상단 고정 카드 (읽기 전용)
            verseCardSection()

            // 템플릿 스위처
            templateSwitcherSection()

            // 템플릿별 입력 섹션
            if viewModel.selectedTemplate == .soap {
                soapTemplateSections()
            } else {
                actsTemplateSections()
            }

            // 저장 버튼
            saveButtonSection()
        }
        .navigationTitle("QT 작성")
        .navigationBarTitleDisplayMode(.inline)
        .alert("저장 실패", isPresented: $viewModel.showSaveErrorAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("저장에 실패했어요. 다시 시도해 주세요.")
        }
        .overlay(alignment: .bottom) {
            if viewModel.showSaveSuccessToast {
                successToast()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
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
    // 상단 말씀 카드 (읽기 전용)
    @ViewBuilder
    func verseCardSection() -> some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                // 구절 제목 (한글 책명 + 장:절)
                Text(draft.verse.id)
                    .font(.headline)
                    .foregroundColor(.blue)

                // 영문 본문
                Text(draft.verse.text)
                    .font(.body)
                    .padding(.vertical, 8)

                // 출처 라벨
                Text("Original: \(draft.verse.translation) (Public Domain)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("오늘의 말씀")
        }

        // 한글 해설 (있는 경우)
        if let korean = draft.korean, !korean.isEmpty {
            Section {
                let lines = korean.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
                if lines.count == 2 {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(lines[0]))
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.purple)

                        Text(String(lines[1]))
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                } else {
                    Text(korean)
                        .font(.body)
                        .foregroundColor(.primary)
                }
            } header: {
                HStack {
                    Image(systemName: "sparkle")
                        .foregroundColor(.purple)
                    Text("구절 해설")
                }
            }
        }

        // 추천 이유 (있는 경우)
        if let rationale = draft.rationale, !rationale.isEmpty {
            Section {
                Text(rationale)
                    .font(.body)
                    .foregroundColor(.secondary)
            } header: {
                Text("추천 이유")
            }
        }
    }

    // 템플릿 스위처
    @ViewBuilder
    func templateSwitcherSection() -> some View {
        Section {
            Picker("템플릿", selection: $viewModel.selectedTemplate) {
                ForEach(QTTemplateType.allCases, id: \.self) { template in
                    Text(template.displayName).tag(template)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("QT 템플릿")
        } footer: {
            Text(viewModel.selectedTemplate == .soap
                 ? "Scripture, Observation, Application, Prayer"
                 : "Adoration, Confession, Thanksgiving, Supplication")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // S.O.A.P 템플릿 섹션들
    @ViewBuilder
    func soapTemplateSections() -> some View {
        // O: Observation
        Section {
            inputField(
                text: $viewModel.soapTemplate.observation,
                placeholder: viewModel.soapTemplate.observationPlaceholder,
                minHeight: 100,
                onChanged: viewModel.updateSOAPObservation
            )
        } header: {
            HStack {
                Text("O")
                    .fontWeight(.bold)
                Text("🔎 Observation (관찰)")
            }
        } footer: {
            characterCounter(for: viewModel.soapTemplate.observation)
        }

        // A: Application
        Section {
            inputField(
                text: $viewModel.soapTemplate.application,
                placeholder: viewModel.soapTemplate.applicationPlaceholder,
                minHeight: 100,
                onChanged: viewModel.updateSOAPApplication
            )
        } header: {
            HStack {
                Text("A")
                    .fontWeight(.bold)
                Text("📝 Application (적용)")
            }
        } footer: {
            characterCounter(for: viewModel.soapTemplate.application)
        }

        // P: Prayer
        Section {
            inputField(
                text: $viewModel.soapTemplate.prayer,
                placeholder: viewModel.soapTemplate.prayerPlaceholder,
                minHeight: 100,
                onChanged: viewModel.updateSOAPPrayer
            )
        } header: {
            HStack {
                Text("P")
                    .fontWeight(.bold)
                Text("🙏 Prayer (기도)")
            }
        } footer: {
            characterCounter(for: viewModel.soapTemplate.prayer)
        }
    }

    // A.C.T.S 템플릿 섹션들
    @ViewBuilder
    func actsTemplateSections() -> some View {
        // A: Adoration
        Section {
            inputField(
                text: $viewModel.actsTemplate.adoration,
                placeholder: viewModel.actsTemplate.adorationPlaceholder,
                minHeight: 100,
                onChanged: viewModel.updateACTSAdoration
            )
        } header: {
            HStack {
                Text("A")
                    .fontWeight(.bold)
                Text("✨ Adoration (찬양)")
            }
        } footer: {
            characterCounter(for: viewModel.actsTemplate.adoration)
        }

        // C: Confession
        Section {
            inputField(
                text: $viewModel.actsTemplate.confession,
                placeholder: viewModel.actsTemplate.confessionPlaceholder,
                minHeight: 100,
                onChanged: viewModel.updateACTSConfession
            )
        } header: {
            HStack {
                Text("C")
                    .fontWeight(.bold)
                Text("💧 Confession (회개)")
            }
        } footer: {
            characterCounter(for: viewModel.actsTemplate.confession)
        }

        // T: Thanksgiving
        Section {
            inputField(
                text: $viewModel.actsTemplate.thanksgiving,
                placeholder: viewModel.actsTemplate.thanksgivingPlaceholder,
                minHeight: 100,
                onChanged: viewModel.updateACTSThanksgiving
            )
        } header: {
            HStack {
                Text("T")
                    .fontWeight(.bold)
                Text("💚 Thanksgiving (감사)")
            }
        } footer: {
            characterCounter(for: viewModel.actsTemplate.thanksgiving)
        }

        // S: Supplication
        Section {
            inputField(
                text: $viewModel.actsTemplate.supplication,
                placeholder: viewModel.actsTemplate.supplicationPlaceholder,
                minHeight: 100,
                onChanged: viewModel.updateACTSSupplication
            )
        } header: {
            HStack {
                Text("S")
                    .fontWeight(.bold)
                Text("🤲 Supplication (간구)")
            }
        } footer: {
            characterCounter(for: viewModel.actsTemplate.supplication)
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
                    .font(.body)
                    .foregroundColor(.secondary.opacity(0.5))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 8)
            }

            TextEditor(text: Binding(
                get: { text.wrappedValue },
                set: { newValue in
                    onChanged(newValue)
                }
            ))
            .frame(minHeight: minHeight)
            .scrollContentBackground(.hidden)
            .textInputAutocapitalization(.sentences)
            .disableAutocorrection(false)
        }
        .padding(8)
        .background(
            viewModel.isEmptyOrWhitespace(text.wrappedValue)
                ? Color(.systemGray6)
                : Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // 글자수 카운터
    @ViewBuilder
    func characterCounter(for text: String) -> some View {
        HStack {
            Spacer()
            Text(viewModel.characterCount(for: text))
                .font(.caption)
                .foregroundColor(viewModel.isOverLimit(for: text) ? .red : .secondary)
        }
    }

    // 저장 버튼 섹션
    @ViewBuilder
    func saveButtonSection() -> some View {
        Section {
            Button(action: {
                Task {
                    await viewModel.saveQT(draft: draft)
                }
            }) {
                HStack {
                    Spacer()
                    Text("저장하기")
                        .bold()
                    Spacer()
                }
            }
            .buttonStyle(.borderless)
            .foregroundColor(.blue)
        }
    }

    // 성공 토스트
    @ViewBuilder
    func successToast() -> some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text("기록이 저장되었습니다")
                .font(.subheadline)
                .foregroundColor(.primary)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 4)
        .padding(.bottom, 50)
    }
}
