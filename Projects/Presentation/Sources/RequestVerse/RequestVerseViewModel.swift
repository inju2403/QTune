//
//  RequestVerseViewModel.swift
//  QTune
//
//  Created by 이승주 on 7/26/25.
//

import Foundation
import Combine
import Domain

@Observable
public final class RequestVerseViewModel {
    public private(set) var state = RequestVerseState()
    let effect = PassthroughSubject<RequestVerseEffect, Never>()

    private let generateVerseUseCase: GenerateVerseUseCase

    public init(generateVerseUseCase: GenerateVerseUseCase) {
        self.generateVerseUseCase = generateVerseUseCase
    }

    func send(_ action: RequestVerseAction) {
        switch action {
        case .onAppear(let userId):
            Task { await loadTodayDraft(userId: userId) }

        case .updateMood(let text):
            state.moodText = String(text.prefix(500))
            state.errorMessage = nil // 입력 시 에러 메시지 초기화

        case .updateNote(let text):
            state.noteText = String(text.prefix(200))

        case .tapRequest:
            Task { await requestVerse() }

        case .tapGoToQT:
            guard let result = state.generatedResult else { return }
            effect.send(.navigateToQTEditor(verse: result.verse, korean: result.korean, rationale: result.rationale))

        case .tapResumeDraft:
            guard let draft = state.todayDraft else { return }
            effect.send(.navigateToEditor(draft))

        case .tapDiscardDraft:
            Task { await discardDraft() }

        case .dismissError:
            state.errorMessage = nil
        }
    }

    private func loadTodayDraft(userId: String) async {
        let draft = await DraftManager.shared.loadTodayDraft(userId: userId)
        await MainActor.run {
            state.todayDraft = draft
            state.showDraftBanner = (draft != nil)
        }
    }

    private func discardDraft() async {
        await DraftManager.shared.clearTodayDraft(userId: "me")
        await MainActor.run {
            state.todayDraft = nil
            state.showDraftBanner = false
        }
    }

    private func requestVerse() async {
        // 1. 입력 검증
        guard state.isValidInput else {
            await MainActor.run {
                state.errorMessage = "오늘의 감정이나 상황을 먼저 입력해 주세요"
            }
            return
        }

        // 2. 로딩 중복 방지
        guard !state.isLoading else { return }

        // 3. 기존 드래프트가 있으면 모달로 충돌 처리
        if state.todayDraft != nil {
            await MainActor.run {
                effect.send(.presentDraftConflict)
            }
            return
        }

        await MainActor.run {
            state.isLoading = true
            state.errorMessage = nil
            state.generatedResult = nil
        }

        do {
            let generated = try await generateVerseUseCase.execute(
                normalizedText: state.moodText,
                userId: "me", // TODO: 실제 userId로 교체 필요
                timeZone: .current
            )

            // 4. 결과를 State에 저장
            let result = GeneratedVerseResult(
                verseRef: "\(generated.verse.book) \(generated.verse.chapter):\(generated.verse.verse)",
                verseText: generated.verse.text,
                verseTextEN: nil,  // TODO: OpenAI API에서 verseTextEN 받아오면 사용
                korean: generated.korean,
                rationale: generated.reason,
                verse: generated.verse,
                isSafe: true  // DomainError.moderationBlocked가 throw되지 않았으므로 안전
            )

            await MainActor.run {
                state.generatedResult = result
                state.isLoading = false
            }

        } catch let error as DomainError {
            // Domain 에러별 처리
            let message: String
            switch error {
            case .validationFailed(let msg):
                message = msg
            case .moderationBlocked(let reason):
                message = "부적절한 내용이 감지되었습니다: \(reason)"
            case .rateLimited:
                message = """
                하루에 최대 10번까지 말씀 추천을 받을 수 있어요.

                오늘은 이미 10번 모두 사용하셨어요.
                내일 다시 부탁드릴게요. 😊
                """
            case .network(let msg):
                message = "네트워크 오류: \(msg)"
            case .configurationError(let msg):
                message = "설정 오류: \(msg)"
            case .unauthorized:
                message = "인증이 필요합니다"
            case .notFound:
                message = "요청하신 항목을 찾을 수 없습니다"
            case .unknown:
                message = "알 수 없는 오류가 발생했습니다"
            }

            await MainActor.run {
                state.errorMessage = message
                state.isLoading = false
                effect.send(.showError(message))
            }
        } catch {
            // 기타 에러
            let message = "말씀 추천에 실패했어요. 잠시 후 다시 시도해 주세요"
            await MainActor.run {
                state.errorMessage = message
                state.isLoading = false
                effect.send(.showError(message))
            }
        }
    }
}
