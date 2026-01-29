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
                VStack(alignment: .leading, spacing: 12) {
                    // Title
                    Text("오늘의 말씀")
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                        .foregroundStyle(DS.Color.deepCocoa)
                        .shimmer()
                        .padding(.top, 16)
                        .padding(.horizontal, 20)

                    // 영어 말씀 (+ 대조역본)
                    verseBlock()

                    // 한글 해설
                    if !viewModel.state.result.korean.isEmpty {
                        explanationBlock()
                    }

                    // 이 말씀이 주어진 이유
                    if !viewModel.state.result.rationale.isEmpty {
                        rationaleBlock()
                    }

                    Spacer()

                    // QT 하러가기 버튼 (중앙 정렬)
                    HStack {
                        Spacer()
                        PrimaryCTAButton(title: "QT 하러가기", icon: "square.and.pencil") {
                            Haptics.tap()
                            viewModel.send(.tapGoToQT)
                        }
                        Spacer()
                    }
                    .padding(.bottom, 16)
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
            .presentationDetents([.height(605)])
        }
    }
}

// MARK: - Subviews

private extension ResultView {
    @ViewBuilder
    func verseBlock() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // 타이틀
            HStack(spacing: 8) {
                Image(systemName: "book.closed.fill")
                    .foregroundStyle(DS.Color.gold)
                    .font(.system(size: 20))
                Text(viewModel.state.result.verseRef)
                    .font(DS.Font.titleM(.semibold))
                    .foregroundStyle(DS.Color.deepCocoa)
            }
            .padding(.bottom, 16)

            // 기본 역본 본문
            Text(viewModel.state.result.verse.text)
                .font(DS.Font.verse(17, .regular))
                .foregroundStyle(DS.Color.textPrimary)
                .lineSpacing(6)
                .padding(.bottom, viewModel.state.result.secondaryVerse != nil ? 12 : 0)

            // 대조역본이 있으면 표시
            if let secondaryVerse = viewModel.state.result.secondaryVerse {
                Text(secondaryVerse.text)
                    .font(DS.Font.verse(17, .regular))
                    .foregroundStyle(DS.Color.textPrimary)
                    .lineSpacing(6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
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

            Text(viewModel.state.result.korean)
                .font(DS.Font.bodyM())
                .foregroundStyle(DS.Color.textPrimary)
                .lineSpacing(6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
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
                Text("이 말씀이 주어진 이유")
                    .font(DS.Font.titleS(.semibold))
                    .foregroundStyle(DS.Color.deepCocoa)
            }

            Text(viewModel.state.result.rationale)
                .font(DS.Font.bodyM())
                .foregroundStyle(DS.Color.textPrimary)
                .lineSpacing(6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.m)
                .fill(DS.Color.canvas.opacity(0.9))
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Preview

#Preview {
    let sampleVerse = Verse(
        book: "Psalm",
        chapter: 23,
        verse: 1,
        text: "The Lord is my shepherd; I shall not want.",
        translation: "KJV"
    )

    let sampleResult = GeneratedVerseResult(
        verseRef: "시편 23:1",
        verseText: "The Lord is my shepherd; I shall not want.",
        verseTextEN: nil,
        korean: "여호와는 나의 목자시니 내게 부족함이 없으리로다\n\n이 구절은 하나님께서 우리의 필요를 채우시는 분이심을 선포합니다. 목자가 양들을 돌보듯, 하나님은 우리 삶의 모든 영역에서 필요한 것을 공급하십니다. 우리가 하나님과 동행할 때, 그분은 우리에게 참된 만족과 평안을 주십니다.",
        rationale: "오늘 여러분이 나누신 일상의 어려움 속에서도 하나님께서 여러분의 필요를 아시고 채워주실 것을 믿으시길 바랍니다. 이 말씀을 통해 하나님의 신실하심을 묵상하며 평안을 얻으시기 바랍니다.",
        verse: sampleVerse,
        isSafe: true
    )

    let state = ResultState(result: sampleResult)
    let viewModel = ResultViewModel(initialState: state)

    NavigationStack {
        ResultView(viewModel: viewModel)
    }
}
