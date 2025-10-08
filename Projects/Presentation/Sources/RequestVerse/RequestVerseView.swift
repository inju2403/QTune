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
    @State private var showError = false
    @State private var errorMessage = ""
    @Binding var path: NavigationPath

    // MARK: - Init
    public init(viewModel: RequestVerseViewModel, path: Binding<NavigationPath>) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _path = path
    }

    // MARK: - Body
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                draftBanner()
                descriptionText()
                inputArea()
                counterRow()
                loadingIndicator()
                requestButton()
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
            case .showError(let msg):
                errorMessage = msg
                showError = true
            case .presentDraftConflict:
                showConflict = true
            case .navigateToEditor(let draft):
                path.append(draft)
            case .showToast:
                break
            }
        }
        .alert("오류", isPresented: $showError) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(errorMessage)
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

    func descriptionText() -> some View {
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

    func inputArea() -> some View {
        let inputBinding = Binding<String>(
            get: { viewModel.state.inputText },
            set: { viewModel.send(.updateInput($0)) }
        )
        return ZStack(alignment: .topLeading) {
            if viewModel.state.inputText.isEmpty {
                Text("예) 오늘은 중요한 시험을 앞두고 너무 긴장되고 불안해요...")
                    .font(.body)
                    .foregroundStyle(.secondary.opacity(0.5))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 8)
            }

            TextEditor(text: inputBinding)
                .frame(minHeight: 180, alignment: .topLeading)
                .scrollContentBackground(.hidden)
                .textInputAutocapitalization(.sentences)
                .disableAutocorrection(false)
        }
        .padding(8)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    func counterRow() -> some View {
        HStack {
            Spacer()
            Text("\(viewModel.state.inputText.count)/500")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    func loadingIndicator() -> some View {
        if viewModel.state.isLoading {
            ProgressView().padding(.vertical, 4)
        }
    }

    func requestButton() -> some View {
        let disabled = viewModel.state.inputText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty

        return Button(action: { viewModel.send(.tapRequest) }) {
            Text("오늘의 말씀 추천받기")
                .bold()
                .frame(maxWidth: .infinity)
                .padding()
        }
        .disabled(disabled)
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
}

