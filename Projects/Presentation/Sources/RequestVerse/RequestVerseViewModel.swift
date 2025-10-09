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
        case .onAppear(let userId):
            Task { await loadTodayDraft(userId: userId) }

        case .updateInput(let text):
            state.inputText = String(text.prefix(500))

        case .tapRequest:
            Task { await requestVerse() }

        case .tapResumeDraft:
            guard let draft = state.todayDraft else { return }
            effect.send(.navigateToEditor(draft))

        case .tapDiscardDraft:
            Task { await discardDraft() }
        }
    }

    private func loadTodayDraft(userId: String) async {
        let draft = await DraftManager.shared.loadTodayDraft(userId: userId)
        state.todayDraft = draft
        state.showDraftBanner = (draft != nil)
    }

    private func discardDraft() async {
        await DraftManager.shared.clearTodayDraft(userId: "me")
        state.todayDraft = nil
        state.showDraftBanner = false
    }

    private func requestVerse() async {
        // 입력 검증: 텍스트 필수
        guard !state.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            effect.send(.showError("오늘의 생각이나 상황을 먼저 입력해 주세요"))
            return
        }

        // 기존 드래프트가 있으면 모달로 충돌 처리
        if state.todayDraft != nil {
            effect.send(.presentDraftConflict)
            return
        }

        state.isLoading = true
        defer { state.isLoading = false }

        do {
            // TODO: ClientPreFilterUseCase 통합 필요
            let generated = try await generateVerseUseCase.execute(
                normalizedText: state.inputText,
                userId: "me", // TODO: 실제 userId로 교체 필요
                timeZone: .current
            )
            let draft = QuietTime(
                id: UUID(),
                verse: generated.verse,
                memo: "",
                date: Date(),
                status: .draft,
                tags: [],
                isFavorite: false,
                updatedAt: Date()
            )
            await DraftManager.shared.saveDraft(draft, userId: "me")
            effect.send(.navigateToEditor(draft))
        } catch {
            effect.send(.showError("말씀 추천에 실패했어요"))
        }
    }
}
