//
//  VerseSearchView.swift
//  Presentation
//
//  Created by 이승주 on 2/18/26.
//

import SwiftUI
import Combine
import Domain

/// 구절 직접 찾기 화면
/// GPT 없이 성경 API에서 특정 구절을 바로 가져옴
public struct VerseSearchView: View {
    @State private var viewModel: VerseSearchViewModel
    @FocusState private var isSearchFocused: Bool
    @Environment(\.dismiss) private var dismiss
    let onGoToQT: (Verse, String?, String?) -> Void

    public init(viewModel: VerseSearchViewModel, onGoToQT: @escaping (Verse, String?, String?) -> Void) {
        _viewModel = State(wrappedValue: viewModel)
        self.onGoToQT = onGoToQT
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                // 배경
                WarmGradientBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        // 역본 선택 탭
                        translationPicker
                            .padding(.top, 4)

                        // 검색 입력창
                        searchField

                        // 에러 메시지
                        if let error = viewModel.state.errorMessage {
                            errorBanner(error)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // 결과 카드
                        if let verse = viewModel.state.result {
                            verseResultCard(verse)
                                .transition(.opacity.combined(with: .scale(scale: 0.97)))
                        }

                        // 로딩
                        if viewModel.state.isLoading {
                            loadingView
                                .transition(.opacity)
                        }

                        // 도움말 힌트 (결과 없을 때)
                        if !viewModel.state.hasResult && !viewModel.state.isLoading {
                            hintCard
                                .transition(.opacity)
                        }

                        Spacer(minLength: 60)
                    }
                    .padding(.horizontal, 20)
                    .animation(.easeInOut(duration: 0.25), value: viewModel.state.result)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.state.isLoading)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.state.errorMessage)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("구절 직접 찾기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        Haptics.tap()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                }
            }
        }
        .onAppear {
            viewModel.send(.onAppear)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isSearchFocused = true
            }
        }
        .onReceive(viewModel.effect) { eff in
            switch eff {
            case .navigateToQTEditor(let verse, let explanation, let suggestedPrayer):
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onGoToQT(verse, explanation, suggestedPrayer)
                }
            }
        }
        .onTapGesture {
            isSearchFocused = false
        }
    }
}

// MARK: - Subviews

private extension VerseSearchView {

    var header: some View {
        HStack(alignment: .center, spacing: 10) {
            // 아이콘
            Image(systemName: "book.closed.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(DS.Color.gold)

            VStack(alignment: .leading, spacing: 2) {
                DSText.titleS("구절 직접 찾기", weight: .bold)
                    .foregroundStyle(DS.Color.deepCocoa)
                DSText.caption("구절 번호를 알고 계시면 바로 찾아드려요")
                    .foregroundStyle(DS.Color.textSec)
            }

            Spacer()

            Button {
                Haptics.tap()
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(DS.Color.textSec.opacity(0.6))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            DS.Color.canvas.opacity(0.95)
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundStyle(DS.Color.divider),
                    alignment: .bottom
                )
        )
    }

    var translationPicker: some View {
        HStack(spacing: 8) {
            ForEach(Translation.allCases, id: \.self) { translation in
                translationTab(translation)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(DS.Color.bgMid)
        )
    }

    func translationTab(_ translation: Translation) -> some View {
        let isSelected = viewModel.state.selectedTranslation == translation

        return Button {
            Haptics.tap()
            viewModel.send(.selectTranslation(translation))
        } label: {
            VStack(spacing: 2) {
                DSText.caption(translation.displayName, weight: isSelected ? .semibold : .medium)
                    .foregroundStyle(isSelected ? .white : DS.Color.textSec)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? DS.Color.gold : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    var searchField: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(viewModel.state.isValidInput ? DS.Color.gold : DS.Color.placeholder)

                TextField("", text: Binding(
                    get: { viewModel.state.searchText },
                    set: { viewModel.send(.updateSearch($0)) }
                ), prompt: Text("예) 시편 37:5, 요한복음 3:16-18")
                    .foregroundStyle(DS.Color.placeholder)
                )
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundStyle(DS.Color.textPrimary)
                .focused($isSearchFocused)
                .submitLabel(.search)
                .onSubmit {
                    if viewModel.state.isValidInput {
                        Haptics.tap()
                        viewModel.send(.tapSearch)
                    }
                }
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

                if !viewModel.state.searchText.isEmpty {
                    Button {
                        Haptics.tap()
                        viewModel.send(.updateSearch(""))
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(DS.Color.textSec.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(DS.Color.canvas)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                viewModel.state.isValidInput ? DS.Color.gold.opacity(0.5) : DS.Color.stroke,
                                lineWidth: 1.5
                            )
                    )
            )

            // 검색 버튼
            Button {
                Haptics.tap()
                isSearchFocused = false
                viewModel.send(.tapSearch)
            } label: {
                HStack(spacing: 8) {
                    if viewModel.state.isLoading {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 16))
                    }
                    DSText.bodyM("구절 찾기", weight: .semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            viewModel.state.isValidInput ?
                            LinearGradient(
                                colors: [DS.Color.gold.opacity(0.9), DS.Color.gold],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(
                    color: viewModel.state.isValidInput ? DS.Color.gold.opacity(0.3) : .clear,
                    radius: 8, y: 4
                )
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.state.isValidInput || viewModel.state.isLoading)
        }
    }

    func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.system(size: 14))

            DSText.bodyM(message)
                .foregroundStyle(DS.Color.textPrimary)
                .multilineTextAlignment(.leading)

            Spacer()

            Button {
                Haptics.tap()
                viewModel.send(.dismissError)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(DS.Color.textSec)
                    .font(.system(size: 16))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }

    func verseResultCard(_ verse: Verse) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // 구절 정보 헤더
            HStack(spacing: 8) {
                Image(systemName: "book.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(DS.Color.gold)

                DSText.bodyM(verse.localizedId, weight: .semibold)
                    .foregroundStyle(DS.Color.deepCocoa)

                Spacer()

                // 역본 뱃지
                Text(Translation.from(code: verse.translation)?.displayName ?? verse.translation)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DS.Color.gold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(DS.Color.gold.opacity(0.12))
                            .overlay(
                                Capsule()
                                    .stroke(DS.Color.gold.opacity(0.3), lineWidth: 1)
                            )
                    )
            }

            // 구분선
            Rectangle()
                .fill(DS.Color.divider)
                .frame(height: 1)

            // 본문
            DSText.verse(verse.text, size: 16)
                .foregroundStyle(DS.Color.textPrimary)
                .multilineTextAlignment(.leading)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)

            // 해설 섹션
            explanationSection

            // QT 하러 가기 버튼
            Button {
                Haptics.success()
                viewModel.send(.tapGoToQT)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 14))
                    DSText.bodyM("이 말씀으로 QT 하기", weight: .semibold)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [DS.Color.accent, DS.Color.accent2],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: DS.Color.accent.opacity(0.3), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(DS.Color.canvas)
                .shadow(color: .black.opacity(0.06), radius: 16, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(DS.Color.gold.opacity(0.15), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.25), value: viewModel.state.explanation)
        .animation(.easeInOut(duration: 0.2), value: viewModel.state.isExplanationLoading)
        .animation(.easeInOut(duration: 0.2), value: viewModel.state.explanationError)
    }

    @ViewBuilder
    var explanationSection: some View {
        // 해설 에러
        if let error = viewModel.state.explanationError {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.orange)

                DSText.caption(error)
                    .foregroundStyle(DS.Color.textSec)
                    .multilineTextAlignment(.leading)

                Spacer()

                Button {
                    Haptics.tap()
                    viewModel.send(.tapFetchExplanation)
                } label: {
                    DSText.caption("다시 시도", weight: .semibold)
                        .foregroundStyle(DS.Color.gold)
                }
                .buttonStyle(.plain)
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
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
        }
        // 해설 로딩 중
        else if viewModel.state.isExplanationLoading {
            HStack(spacing: 10) {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(DS.Color.gold)

                DSText.caption("AI가 말씀을 해설하는 중...")
                    .foregroundStyle(DS.Color.textSec)

                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(DS.Color.bgMid)
            )
            .transition(.opacity)
        }
        // 해설 완료
        else if let explanation = viewModel.state.explanation {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundStyle(DS.Color.gold)

                    DSText.caption("AI 해설", weight: .semibold)
                        .foregroundStyle(DS.Color.gold)
                }

                DSText.bodyM(explanation)
                    .foregroundStyle(DS.Color.textPrimary)
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(DS.Color.gold.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(DS.Color.gold.opacity(0.2), lineWidth: 1)
                    )
            )
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
        }
        // 해설 버튼 (아직 요청 전, useCase 있을 때만)
        else if viewModel.state.isExplanationAvailable && viewModel.state.result != nil {
            Button {
                Haptics.tap()
                viewModel.send(.tapFetchExplanation)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13))
                    DSText.bodyM("AI 해설 받기", weight: .medium)
                }
                .foregroundStyle(DS.Color.gold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(DS.Color.gold.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(DS.Color.gold.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .transition(.opacity)
        }
    }

    var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(DS.Color.gold)

            DSText.caption("말씀을 가져오는 중...")
                .foregroundStyle(DS.Color.textSec)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    var hintCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(DS.Color.gold)
                DSText.caption("입력 가이드", weight: .semibold)
                    .foregroundStyle(DS.Color.cocoa)
            }

            VStack(alignment: .leading, spacing: 8) {
                hintRow("시편 37:5", description: "단일 구절")
                hintRow("요한복음 3:16-18", description: "연속 구절 범위")
                hintRow("잠 3:5", description: "약어 사용 가능")
                hintRow("John 3:16", description: "영어 책명도 가능")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(DS.Color.gold.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(DS.Color.gold.opacity(0.2), lineWidth: 1)
                )
        )
    }

    func hintRow(_ example: String, description: String) -> some View {
        HStack(spacing: 8) {
            Text(example)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(DS.Color.deepCocoa)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(DS.Color.canvas)
                )

            Text("→ \(description)")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(DS.Color.textSec)
        }
    }

}

