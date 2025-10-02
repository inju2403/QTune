//
//  RequestVerseViewModel.swift
//  QTune
//
//  Created by 이승주 on 7/26/25.
//

import Foundation
import Combine
import Domain

@MainActor
public final class RequestVerseViewModel: ObservableObject {
    @Published var state = RequestVerseState()
    let effect = PassthroughSubject<RequestVerseEffect, Never>()

    private let generateVerseUseCase: GenerateVerseUseCase

    public init(generateVerseUseCase: GenerateVerseUseCase) {
        self.generateVerseUseCase = generateVerseUseCase
    }

    func send(_ action: RequestVerseAction) {
        switch action {
        case .updateInput(let text):
            state.inputText = text

        case .tapRequest:
            Task {
                await requestVerse()
            }
        }
    }

    private func requestVerse() async {
        guard !state.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            effect.send(.showError("입력된 내용이 없어요"))
            return
        }

        state.isLoading = true
        defer { state.isLoading = false }

        do {
            let generated = try await generateVerseUseCase.execute(prompt: state.inputText)
            effect.send(.navigateToResult(generated))
        } catch {
            effect.send(.showError("말씀 추천에 실패했어요"))
        }
    }

}
