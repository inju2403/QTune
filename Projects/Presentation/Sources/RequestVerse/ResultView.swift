//
//  ResultView.swift
//  Presentation
//
//  Created by 이승주 on 10/19/25.
//

import SwiftUI
import Domain

/// 추천 결과 화면 (영어 + 해설 + 이유 + "QT 하러가기" 버튼)
public struct ResultView: View {
    // MARK: - ViewModel
    @State private var viewModel: ResultViewModel

    // MARK: - Init
    public init(viewModel: ResultViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    // MARK: - Body
    public var body: some View {
        ZStack {
            CrossSunsetBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Title
                    Text("오늘의 말씀")
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                        .foregroundStyle(DS.Color.deepCocoa)
                        .shimmer()
                        .padding(.top, 28)
                        .padding(.horizontal, 20)

                    // 영어 말씀
                    verseBlock()

                    // 한글 해설
                    if !viewModel.state.result.korean.isEmpty {
                        explanationBlock()
                    }

                    // 추천 이유
                    if !viewModel.state.result.rationale.isEmpty {
                        rationaleBlock()
                    }

                    Spacer(minLength: 20)

                    // QT 하러가기 버튼 (중앙 정렬)
                    HStack {
                        Spacer()
                        PrimaryCTAButton(title: "QT 하러가기", icon: "hand.raised.fill") {
                            Haptics.tap()
                            viewModel.send(.tapGoToQT)
                        }
                        Spacer()
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: Binding(
            get: { viewModel.state.showTemplateSheet },
            set: { if !$0 { viewModel.send(.dismissSheet) } }
        )) {
            TemplatePickerSheet { template in
                Haptics.tap()
                viewModel.send(.selectTemplate(template))
            }
            .presentationDetents([.height(580)])
        }
    }
}

// MARK: - Subviews

private extension ResultView {
    @ViewBuilder
    func verseBlock() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "book.closed.fill")
                    .foregroundStyle(DS.Color.gold)
                    .font(.system(size: 20))
                Text(viewModel.state.result.verseRef)
                    .font(DS.Font.titleM(.semibold))
                    .foregroundStyle(DS.Color.deepCocoa)
            }

            Text(viewModel.state.result.verse.text)
                .font(DS.Font.verse(17, .regular))
                .foregroundStyle(DS.Color.textPrimary)
                .lineSpacing(6)
                .padding(.bottom, 12)

            // 번역본 표시 (좌측 정렬)
            HStack(spacing: 6) {
                Image(systemName: "text.book.closed")
                    .font(.system(size: 11))
                    .foregroundStyle(DS.Color.gold.opacity(0.7))

                Text(viewModel.state.result.verse.translation.uppercased())
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(DS.Color.gold.opacity(0.8))

                Text("·")
                    .foregroundStyle(DS.Color.textSecondary.opacity(0.5))

                Text("Public Domain")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(DS.Color.textSecondary.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.m)
                .fill(DS.Color.canvas.opacity(0.9))
        )
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    func explanationBlock() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(DS.Color.gold)
                Text("해설")
                    .font(DS.Font.titleM(.semibold))
                    .foregroundStyle(DS.Color.deepCocoa)
            }

            // 첫 줄이 볼드인 경우 분리
            let lines = viewModel.state.result.korean.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
            if lines.count == 2 {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(lines[0]))
                        .font(DS.Font.bodyL(.semibold))
                        .foregroundStyle(DS.Color.gold)

                    Text(String(lines[1]))
                        .font(DS.Font.bodyM())
                        .foregroundStyle(DS.Color.textPrimary)
                        .lineSpacing(6)
                }
            } else {
                Text(viewModel.state.result.korean)
                    .font(DS.Font.bodyM())
                    .foregroundStyle(DS.Color.textPrimary)
                    .lineSpacing(6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.m)
                .fill(DS.Color.canvas.opacity(0.9))
        )
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    func rationaleBlock() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(DS.Color.gold)
                Text("추천 이유")
                    .font(DS.Font.titleM(.semibold))
                    .foregroundStyle(DS.Color.deepCocoa)
            }

            Text(viewModel.state.result.rationale)
                .font(DS.Font.bodyM())
                .foregroundStyle(DS.Color.textPrimary)
                .lineSpacing(6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.m)
                .fill(DS.Color.canvas.opacity(0.9))
        )
        .padding(.horizontal, 20)
    }
}
