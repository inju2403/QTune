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
        ScrollView {
            VStack(spacing: 24) {
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
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle("오늘의 말씀")
        .navigationBarTitleDisplayMode(.large)
        .scrollDismissesKeyboard(.interactively)
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
            case .navigateToQTEditor(let verse, let rationale):
                // QT 작성 화면으로 이동 (rationale을 memo에 임시 저장)
                let draft = QuietTime(
                    id: UUID(),
                    verse: verse,
                    memo: rationale,  // 추천 이유를 memo에 저장
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
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("오늘 작성 중인 QT가 있어요").bold()
                    Text("이어 쓰거나 삭제할 수 있어요")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("이어쓰기") { viewModel.send(.tapResumeDraft) }
                Button("삭제") { viewModel.send(.tapDiscardDraft) }
            }
            .padding(12)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    func descriptionSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("오늘 하루는 어떠셨나요?")
                .font(.title3)
                .fontWeight(.semibold)

            Text("오늘의 생각, 감정, 상황을 자유롭게 적어보세요")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func inputSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // 감정/상황 입력 (필수)
            VStack(alignment: .leading, spacing: 8) {
                Text("감정/상황 (필수)")
                    .font(.subheadline)
                    .fontWeight(.medium)

                moodInputArea()

                HStack {
                    Spacer()
                    Text("\(viewModel.state.moodText.count)/500")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            // 추가 메모 (선택)
            VStack(alignment: .leading, spacing: 8) {
                Text("추가 메모 (선택)")
                    .font(.subheadline)
                    .fontWeight(.medium)

                noteInputArea()

                HStack {
                    Spacer()
                    Text("\(viewModel.state.noteText.count)/200")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
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
                    .font(.body)
                    .foregroundStyle(.secondary.opacity(0.5))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 8)
            }

            TextEditor(text: binding)
                .frame(minHeight: 120, alignment: .topLeading)
                .scrollContentBackground(.hidden)
                .textInputAutocapitalization(.sentences)
                .disableAutocorrection(false)
        }
        .padding(8)
        .background(Color(.systemGray6))
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
                    .font(.body)
                    .foregroundStyle(.secondary.opacity(0.5))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 8)
            }

            TextEditor(text: binding)
                .frame(minHeight: 80, alignment: .topLeading)
                .scrollContentBackground(.hidden)
                .textInputAutocapitalization(.sentences)
                .disableAutocorrection(false)
        }
        .padding(8)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    func errorSection() -> some View {
        if let errorMessage = viewModel.state.errorMessage {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)

                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Spacer()

                Button(action: { viewModel.send(.dismissError) }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .background(Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    @ViewBuilder
    func loadingIndicator() -> some View {
        if viewModel.state.isLoading {
            HStack {
                Spacer()
                ProgressView()
                    .controlSize(.regular)
                Text("말씀을 추천하고 있어요...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.vertical, 12)
        }
    }

    func requestButton() -> some View {
        Button(action: { viewModel.send(.tapRequest) }) {
            Text("오늘의 말씀 추천받기")
                .bold()
                .frame(maxWidth: .infinity)
                .padding()
        }
        .disabled(!viewModel.state.isValidInput || viewModel.state.isLoading)
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }

    @ViewBuilder
    func resultSection() -> some View {
        if let result = viewModel.state.generatedResult, result.isSafe {
            VStack(alignment: .leading, spacing: 16) {
                Divider()
                    .padding(.vertical, 8)

                // 결과 헤더
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("추천 말씀")
                        .font(.title3)
                        .fontWeight(.bold)
                }

                // verseRef
                Text(result.verseRef)
                    .font(.headline)
                    .foregroundColor(.blue)

                // verseText
                Text(result.verseText)
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                // rationale
                if !result.rationale.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("추천 이유")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)

                        Text(result.rationale)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    @ViewBuilder
    func goToQTButton() -> some View {
        if viewModel.state.hasResult {
            Button(action: { viewModel.send(.tapGoToQT) }) {
                HStack {
                    Text("QT 하러 가기")
                        .bold()
                    Image(systemName: "arrow.right")
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.green)
        }
    }
}
