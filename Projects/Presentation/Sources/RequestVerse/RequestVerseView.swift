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
    @Binding var path: NavigationPath

    // MARK: - Init
    public init(viewModel: RequestVerseViewModel, path: Binding<NavigationPath>) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _path = path
    }

    // MARK: - Body
    public var body: some View {
        ZStack {
            AppBackgroundView()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: DS.Spacing.xl) {
                    draftBanner()
                    descriptionSection()
                    inputSection()
                    errorSection()
                    loadingIndicator()
                    requestButton()
                    resultSection()
                    goToQTButton()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DS.Spacing.l)
                .padding(.vertical, DS.Spacing.l)
            }
            .navigationTitle("오늘의 말씀")
            .navigationBarTitleDisplayMode(.large)
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear {
            viewModel.send(.onAppear(userId: "me"))
        }
        .onReceive(viewModel.effect) { eff in
            switch eff {
            case .showError:
                break // errorMessage는 state에서 처리
            case .presentDraftConflict:
                showConflict = true
            case .navigateToEditor(let draft):
                path.append(draft)
            case .navigateToQTEditor(let verse, let korean, let rationale):
                // QT 작성 화면으로 이동
                let draft = QuietTime(
                    id: UUID(),
                    verse: verse,
                    memo: "",  // 사용자 메모는 빈 문자열로 시작
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
            SoftCard {
                HStack(spacing: DS.Spacing.m) {
                    Image(systemName: "doc.text")
                        .foregroundStyle(DS.Color.gold)
                        .font(DS.Font.titleM())

                    VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                        Text("오늘 작성 중인 QT가 있어요")
                            .font(DS.Font.bodyL(.semibold))
                            .foregroundStyle(DS.Color.textPrimary)
                        Text("이어 쓰거나 삭제할 수 있어요")
                            .font(DS.Font.caption())
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                    Spacer()
                    Button("이어쓰기") {
                        Haptics.tap()
                        viewModel.send(.tapResumeDraft)
                    }
                    .font(DS.Font.bodyM(.semibold))
                    .foregroundStyle(DS.Color.olive)

                    Button("삭제") {
                        Haptics.tap()
                        viewModel.send(.tapDiscardDraft)
                    }
                    .font(DS.Font.bodyM(.semibold))
                    .foregroundStyle(DS.Color.textSecondary)
                }
            }
        }
    }

    func descriptionSection() -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            SectionHeader(icon: "heart.text.square", title: "오늘 하루는 어떠셨나요?")

            Text("오늘의 생각, 감정, 상황을 자유롭게 적어보세요")
                .font(DS.Font.bodyM())
                .foregroundStyle(DS.Color.textSecondary)
                .padding(.horizontal, DS.Spacing.m)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func inputSection() -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.l) {
            // 감정/상황 입력 (필수)
            SoftCard {
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(DS.Color.gold)
                            .font(DS.Font.bodyL())
                        Text("감정/상황 (필수)")
                            .font(DS.Font.bodyL(.semibold))
                            .foregroundStyle(DS.Color.textPrimary)
                        Spacer()
                        Text("\(viewModel.state.moodText.count)/500")
                            .font(DS.Font.caption())
                            .foregroundStyle(DS.Color.textSecondary)
                    }

                    moodInputArea()
                }
            }

            // 추가 메모 (선택)
            SoftCard {
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    HStack {
                        Image(systemName: "note.text")
                            .foregroundStyle(DS.Color.olive)
                            .font(DS.Font.bodyL())
                        Text("추가 메모 (선택)")
                            .font(DS.Font.bodyL(.semibold))
                            .foregroundStyle(DS.Color.textPrimary)
                        Spacer()
                        Text("\(viewModel.state.noteText.count)/200")
                            .font(DS.Font.caption())
                            .foregroundStyle(DS.Color.textSecondary)
                    }

                    noteInputArea()
                }
            }
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
                    .font(DS.Font.bodyM())
                    .foregroundStyle(DS.Color.textSecondary.opacity(0.4))
                    .padding(.horizontal, DS.Spacing.xs)
                    .padding(.vertical, DS.Spacing.s)
            }

            TextEditor(text: binding)
                .font(DS.Font.bodyM())
                .foregroundStyle(DS.Color.textPrimary)
                .frame(minHeight: 120, alignment: .topLeading)
                .scrollContentBackground(.hidden)
                .textInputAutocapitalization(.sentences)
                .disableAutocorrection(false)
        }
        .padding(DS.Spacing.s)
        .background(DS.Color.background)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.s))
    }

    func noteInputArea() -> some View {
        let binding = Binding<String>(
            get: { viewModel.state.noteText },
            set: { viewModel.send(.updateNote($0)) }
        )

        return ZStack(alignment: .topLeading) {
            if viewModel.state.noteText.isEmpty {
                Text("예) 최선을 다했지만 결과가 걱정돼요")
                    .font(DS.Font.bodyM())
                    .foregroundStyle(DS.Color.textSecondary.opacity(0.4))
                    .padding(.horizontal, DS.Spacing.xs)
                    .padding(.vertical, DS.Spacing.s)
            }

            TextEditor(text: binding)
                .font(DS.Font.bodyM())
                .foregroundStyle(DS.Color.textPrimary)
                .frame(minHeight: 80, alignment: .topLeading)
                .scrollContentBackground(.hidden)
                .textInputAutocapitalization(.sentences)
                .disableAutocorrection(false)
        }
        .padding(DS.Spacing.s)
        .background(DS.Color.background)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.s))
    }

    @ViewBuilder
    func errorSection() -> some View {
        if let errorMessage = viewModel.state.errorMessage {
            SoftCard {
                HStack(spacing: DS.Spacing.m) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(DS.Font.bodyL())

                    Text(errorMessage)
                        .font(DS.Font.bodyM())
                        .foregroundStyle(DS.Color.textPrimary)

                    Spacer()

                    Button {
                        Haptics.tap()
                        viewModel.send(.dismissError)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(DS.Color.textSecondary)
                            .font(DS.Font.bodyL())
                    }
                }
            }
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    @ViewBuilder
    func loadingIndicator() -> some View {
        if viewModel.state.isLoading {
            VStack(spacing: DS.Spacing.l) {
                HStack(spacing: DS.Spacing.m) {
                    Spacer()
                    ProgressView()
                        .controlSize(.regular)
                        .tint(DS.Color.gold)
                    Text("말씀을 추천하고 있어요...")
                        .font(DS.Font.bodyM())
                        .foregroundStyle(DS.Color.textSecondary)
                    Spacer()
                }
                .padding(.vertical, DS.Spacing.m)

                // Loading skeleton
                VerseCardView(title: "추천 말씀") {
                    VStack(alignment: .leading, spacing: DS.Spacing.m) {
                        Text("요한복음 3:16")
                            .font(DS.Font.bodyL(.semibold))
                        Text("하나님이 세상을 이처럼 사랑하사 독생자를 주셨으니...")
                            .font(DS.Font.bodyL())
                            .lineLimit(3)
                    }
                }
                .redacted(reason: .placeholder)
            }
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }

    func requestButton() -> some View {
        PrimaryButton(title: "오늘의 말씀 추천받기", icon: "sparkles") {
            viewModel.send(.tapRequest)
        }
        .disabled(!viewModel.state.isValidInput || viewModel.state.isLoading)
        .opacity((!viewModel.state.isValidInput || viewModel.state.isLoading) ? 0.5 : 1)
        .animation(Motion.appear, value: viewModel.state.isValidInput)
    }

    @ViewBuilder
    func resultSection() -> some View {
        if let result = viewModel.state.generatedResult, result.isSafe {
            VStack(alignment: .leading, spacing: DS.Spacing.xl) {
                // Success header with glow
                HStack(spacing: DS.Spacing.m) {
                    ZStack {
                        Circle()
                            .fill(DS.Color.success.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .blur(radius: 8)
                            .animation(Motion.halo, value: true)

                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(DS.Color.success)
                            .font(DS.Font.titleL())
                    }

                    Text("추천 말씀")
                        .font(DS.Font.titleL(.semibold))
                        .foregroundStyle(DS.Color.textPrimary)
                }
                .padding(.top, DS.Spacing.m)
                .onAppear {
                    Haptics.success()
                }

                // Verse reference
                HStack {
                    Image(systemName: "book.closed.fill")
                        .foregroundStyle(DS.Color.gold)
                    Text(result.verseRef)
                        .font(DS.Font.titleM(.semibold))
                        .foregroundStyle(DS.Color.deepCocoa)
                }
                .padding(.horizontal, DS.Spacing.m)

                // Verse text (English)
                VerseCardView(title: "본문") {
                    Text(result.verseText)
                        .lineSpacing(4)
                }

                // Korean interpretation
                if !result.korean.isEmpty {
                    VerseCardView(title: "해설") {
                        let lines = result.korean.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
                        if lines.count == 2 {
                            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                                Text(String(lines[0]))
                                    .font(DS.Font.bodyL(.semibold))
                                    .foregroundStyle(DS.Color.gold)
                                Text(String(lines[1]))
                                    .lineSpacing(4)
                            }
                        } else {
                            Text(result.korean)
                                .lineSpacing(4)
                        }
                    }
                }

                // Rationale
                if !result.rationale.isEmpty {
                    VerseCardView(title: "추천 이유") {
                        Text(result.rationale)
                            .lineSpacing(4)
                    }
                }
            }
        }
    }

    @ViewBuilder
    func goToQTButton() -> some View {
        if viewModel.state.hasResult {
            PrimaryButton(title: "QT 하러 가기", icon: "arrow.right") {
                viewModel.send(.tapGoToQT)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .padding(.bottom, DS.Spacing.l)
        }
    }
}
