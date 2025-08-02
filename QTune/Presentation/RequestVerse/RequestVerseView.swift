//
//  RequestVerseView.swift
//  QTune
//
//  Created by 이승주 on 7/26/25.
//

import SwiftUI

struct RequestVerseView: View {
    @StateObject private var viewModel: RequestVerseViewModel

    init(viewModel: RequestVerseViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("오늘의 감정이나 상황을 입력해 주세요")
                .font(.headline)

            TextEditor(text: $viewModel.state.inputText)
                .frame(height: 150)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.4))
                )
                .padding(.horizontal)

            if viewModel.state.isLoading {
                ProgressView()
            } else {
                Button {
                    viewModel.send(.tapRequest)
                } label: {
                    Text("말씀 추천받기")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }

            Spacer()
        }
        .padding(.top)
        .navigationTitle("오늘의 말씀")

        // 구현 예정: 에러 alert, navigation 처리
    }
}

#Preview {
    let verse = Verse(
        book: "요한복음",
        chapter: 3,
        verse: 16,
        text: "하나님이 세상을 이처럼 사랑하사 독생자를 주셨으니...",
        translation: "개역개정"
    )

    let generated = GeneratedVerse(
        verse: verse,
        reason: "하나님의 사랑을 느끼고 위로받을 수 있는 말씀이에요."
    )

    let repository = DefaultVerseRepository()
    let useCase = GenerateVerseInteractor(repository: repository)
    let viewModel = RequestVerseViewModel(generateVerseUseCase: useCase)

    return NavigationStack {
        RequestVerseView(viewModel: viewModel)
    }
}
