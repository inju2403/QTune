//
//  RequestVerseView.swift
//  QTune
//
//  Created by 이승주 on 7/26/25.
//

import SwiftUI
import Domain

public struct RequestVerseView: View {
    // MARK: - State
    @StateObject private var viewModel: RequestVerseViewModel
    @State private var showConflict = false
    @State private var resultPhase: ResultPhase = .idle
    @Binding var path: NavigationPath
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Init
    public init(viewModel: RequestVerseViewModel, path: Binding<NavigationPath>) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _path = path
    }

    // MARK: - Body
    public var body: some View {
        ZStack {
            CrossSunsetBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    // Title with shimmer
                    Text("오늘의 말씀")
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                        .foregroundStyle(DSColor.textSec)
                        .shimmer()
                        .padding(.top, 28)

                    draftBanner()
                    descriptionSection()
                    inputSection()
                    errorSection()

                    PrimaryCTAButton(title: "오늘의 말씀 추천받기") {
                        Task {
                            resultPhase = .loading
                            viewModel.send(.tapRequest)
                        }
                    }
                    .padding(.top, 8)

                    if resultPhase == .loading {
                        skeleton()
                    }

                    if (resultPhase == .expanding || resultPhase == .expanded),
                       let result = viewModel.state.generatedResult, result.isSafe {
                        resultContent(result: result)
                    }
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)

            // Loading overlay
            if resultPhase == .loading {
                LoadingOverlay()
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            viewModel.send(.onAppear(userId: "me"))
        }
        .onReceive(viewModel.effect) { eff in
            switch eff {
            case .showError:
                resultPhase = .idle
            case .presentDraftConflict:
                showConflict = true
            case .navigateToEditor(let draft):
                path.append(draft)
            case .navigateToQTEditor(let verse, let korean, let rationale):
                let draft = QuietTime(
                    id: UUID(),
                    verse: verse,
                    memo: "",
                    korean: korean,
                    rationale: rationale,
                    date: Date(),
                    status: .draft,
                    tags: [],
                    isFavorite: false,
                    updatedAt: Date()
                )
                path.append(draft)
            case .showToast:
                break
            }
        }
        .onChange(of: viewModel.state.generatedResult) { newValue in
            if newValue != nil {
                withAnimation {
                    resultPhase = .expanding
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    withAnimation {
                        resultPhase = .expanded
                    }
                    Haptics.success()
                }
            } else if resultPhase != .loading {
                resultPhase = .idle
            }
        }
        .confirmationDialog("작성 중인 QT가 있어요",
                            isPresented: $showConflict,
                            titleVisibility: .visible) {
            Button("이어쓰기") { viewModel.send(.tapResumeDraft) }
            Button("새로 시작", role: .destructive) {
                viewModel.send(.tapDiscardDraft)
                viewModel.send(.tapRequest)
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("새로 시작하면 기존 초안은 삭제돼요. 어떻게 할까요?")
        }
    }
}

// MARK: - Subviews
private extension RequestVerseView {
    @ViewBuilder
    func draftBanner() -> some View {
        if viewModel.state.showDraftBanner {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .foregroundStyle(DSColor.gold)
                        .font(.system(size: 20))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("오늘 작성 중인 QT가 있어요")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.95))
                        Text("이어 쓰거나 삭제할 수 있어요")
                            .font(.system(size: 14))
                            .foregroundStyle(DSColor.textSec)
                    }
                    Spacer()
                }

                HStack(spacing: 12) {
                    Button("이어쓰기") {
                        Haptics.tap()
                        viewModel.send(.tapResumeDraft)
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(DSColor.accent)

                    Button("삭제") {
                        Haptics.tap()
                        viewModel.send(.tapDiscardDraft)
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(DSColor.textSec)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(DSColor.card.opacity(0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
        }
    }

    func descriptionSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "heart.text.square")
                    .foregroundStyle(DSColor.gold)
                Text("오늘 하루는 어떠셨나요?")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.95))
            }

            Text("오늘의 생각, 감정, 상황을 자유롭게 적어보세요")
                .font(.system(size: 15))
                .foregroundStyle(DSColor.textSec)
        }
    }

    func inputSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // 감정/상황 입력
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(DSColor.gold)
                    Text("감정/상황 (필수)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                    Spacer()
                    Text("\(viewModel.state.moodText.count)/500")
                        .font(.system(size: 13))
                        .foregroundStyle(DSColor.textSec)
                }

                moodInputArea()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(DSColor.card.opacity(0.9))
            )

            // 추가 메모
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "note.text")
                        .foregroundStyle(DSColor.olive)
                    Text("추가 메모 (선택)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                    Spacer()
                    Text("\(viewModel.state.noteText.count)/200")
                        .font(.system(size: 13))
                        .foregroundStyle(DSColor.textSec)
                }

                noteInputArea()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(DSColor.card.opacity(0.9))
            )
        }
    }

    func moodInputArea() -> some View {
        let binding = Binding<String>(
            get: { viewModel.state.moodText },
            set: { viewModel.send(.updateMood($0)) }
        )

        return ZStack(alignment: .topLeading) {
            if viewModel.state.moodText.isEmpty {
                Text("예) 오늘은 중요한 시험을 앞두고 너무 긴장되고 불안해요...")
                    .font(.system(size: 16))
                    .foregroundStyle(DSColor.textPri.opacity(0.3))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 8)
            }

            TextEditor(text: binding)
                .font(.system(size: 16))
                .foregroundStyle(DSColor.textPri)
                .frame(minHeight: 120)
                .scrollContentBackground(.hidden)
                .textInputAutocapitalization(.sentences)
                .disableAutocorrection(false)
        }
        .padding(8)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    func noteInputArea() -> some View {
        let binding = Binding<String>(
            get: { viewModel.state.noteText },
            set: { viewModel.send(.updateNote($0)) }
        )

        return ZStack(alignment: .topLeading) {
            if viewModel.state.noteText.isEmpty {
                Text("예) 최선을 다했지만 결과가 걱정돼요")
                    .font(.system(size: 16))
                    .foregroundStyle(DSColor.textPri.opacity(0.3))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 8)
            }

            TextEditor(text: binding)
                .font(.system(size: 16))
                .foregroundStyle(DSColor.textPri)
                .frame(minHeight: 80)
                .scrollContentBackground(.hidden)
                .textInputAutocapitalization(.sentences)
                .disableAutocorrection(false)
        }
        .padding(8)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    func errorSection() -> some View {
        if let errorMessage = viewModel.state.errorMessage {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)

                Text(errorMessage)
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.95))

                Spacer()

                Button {
                    Haptics.tap()
                    viewModel.send(.dismissError)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(DSColor.textSec)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.orange.opacity(0.2))
            )
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    @ViewBuilder
    func skeleton() -> some View {
        VStack(spacing: 14) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 22)
                    .fill(DSColor.card.opacity(0.7))
                    .frame(height: 140)
                    .redacted(reason: .placeholder)
                    .shimmer()
            }
        }
    }

    @ViewBuilder
    func resultContent(result: GeneratedVerseResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(icon: "checkmark.circle.fill", title: "추천 말씀")

            ExpandableCard(title: result.verse.id, delay: 0.00) {
                Text(result.verse.text)
                    .lineSpacing(4)
            }

            if !result.korean.isEmpty {
                ExpandableCard(title: "해설", delay: 0.06) {
                    let lines = result.korean.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
                    if lines.count == 2 {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(String(lines[0]))
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(DSColor.gold)

                            Text(String(lines[1]))
                                .lineSpacing(4)
                        }
                    } else {
                        Text(result.korean)
                            .lineSpacing(4)
                    }
                }
            }

            if !result.rationale.isEmpty {
                ExpandableCard(title: "추천 이유", delay: 0.12) {
                    Text(result.rationale)
                        .lineSpacing(4)
                }
            }

            PrimaryCTAButton(title: "QT 하러 가기", icon: "hand.raised.fill") {
                viewModel.send(.tapGoToQT)
            }
            .padding(.top, 4)
        }
    }

    @ViewBuilder
    func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(DSColor.gold)
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white.opacity(0.95))
            Spacer()
        }
        .padding(.top, 6)
    }
}
