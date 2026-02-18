//
//  VerseSearchViewModel.swift
//  Presentation
//
//  Created by 이승주 on 2/18/26.
//

import Foundation
import Combine
import Domain

@Observable
public final class VerseSearchViewModel {
    public private(set) var state = VerseSearchState()
    let effect = PassthroughSubject<VerseSearchEffect, Never>()

    private let fetchVerseDirectUseCase: FetchVerseDirectUseCase
    private let fetchVerseExplanationUseCase: FetchVerseExplanationUseCase?

    private static let recentSearchesKey = "VerseSearch.recentSearches"
    private static let maxRecentCount = 10

    public init(
        fetchVerseDirectUseCase: FetchVerseDirectUseCase,
        fetchVerseExplanationUseCase: FetchVerseExplanationUseCase? = nil
    ) {
        self.fetchVerseDirectUseCase = fetchVerseDirectUseCase
        self.fetchVerseExplanationUseCase = fetchVerseExplanationUseCase
        state.isExplanationAvailable = fetchVerseExplanationUseCase != nil
    }

    func send(_ action: VerseSearchAction) {
        switch action {
        case .onAppear:
            loadRecentSearches()

        case .updateSearch(let text):
            state.searchText = text
            state.errorMessage = nil
            // 텍스트가 바뀌면 기존 결과 및 해설 초기화
            if state.result != nil {
                state.result = nil
                state.explanation = nil
                state.explanationError = nil
            }

        case .selectTranslation(let translation):
            state.selectedTranslation = translation
            // 이미 결과가 있으면 새 역본으로 다시 검색
            if state.result != nil {
                state.explanation = nil
                state.explanationError = nil
                Task { await searchVerse() }
            }

        case .tapSearch:
            Task { await searchVerse() }

        case .tapGoToQT:
            guard let verse = state.result else { return }
            effect.send(.navigateToQTEditor(verse: verse, explanation: state.explanation))

        case .dismissError:
            state.errorMessage = nil

        case .tapRecentSearch(let ref):
            state.searchText = ref
            state.errorMessage = nil
            state.result = nil
            state.explanation = nil
            state.explanationError = nil
            Task { await searchVerse() }

        case .clearRecentSearches:
            state.recentSearches = []
            UserDefaults.standard.removeObject(forKey: Self.recentSearchesKey)

        case .tapFetchExplanation:
            Task { await fetchExplanation() }

        case .dismissExplanationError:
            state.explanationError = nil
        }
    }

    // MARK: - Private

    private func searchVerse() async {
        guard state.isValidInput else {
            await MainActor.run {
                state.errorMessage = "구절을 입력해주세요. 예) 시편 37:5, 요 3:16"
            }
            return
        }
        guard !state.isLoading else { return }

        let query = state.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let translation = state.selectedTranslation.code

        await MainActor.run {
            state.isLoading = true
            state.errorMessage = nil
            state.result = nil
        }

        do {
            let verse = try await fetchVerseDirectUseCase.execute(
                verseRef: query,
                translation: translation
            )

            await MainActor.run {
                state.result = verse
                state.isLoading = false
                addToRecentSearches(query)
            }
        } catch {
            await MainActor.run {
                state.isLoading = false
                state.errorMessage = makeErrorMessage(error)
            }
        }
    }

    private func fetchExplanation() async {
        guard let verse = state.result,
              let useCase = fetchVerseExplanationUseCase else { return }
        guard !state.isExplanationLoading else { return }

        // WEB(영어) 본문이 있어야 해설 가능
        // Verse.text가 영어(WEB/KJV) 본문 - 구절 조회 시 영어 API로 가져온 것
        // selectedTranslation이 한글이면 영어 역본으로 별도 조회가 필요하지만,
        // 현재는 verse.text를 그대로 사용 (API가 WEB/KJV 영어를 반환하므로)
        let englishText = verse.text
        let verseRef = "\(verse.book) \(verse.chapter):\(verse.verse)"

        await MainActor.run {
            state.isExplanationLoading = true
            state.explanationError = nil
        }

        do {
            let explanation = try await useCase.execute(
                englishText: englishText,
                verseRef: verseRef
            )
            await MainActor.run {
                state.explanation = explanation
                state.isExplanationLoading = false
            }
        } catch {
            await MainActor.run {
                state.isExplanationLoading = false
                state.explanationError = "해설을 가져오지 못했어요. 잠시 후 다시 시도해주세요."
            }
        }
    }

    private func makeErrorMessage(_ error: Error) -> String {
        let msg = error.localizedDescription.lowercased()
        if msg.contains("not found") || msg.contains("404") {
            return "구절을 찾을 수 없어요. 구절 형식을 확인해주세요.\n예) 시편 37:5, 요한복음 3:16-18"
        } else if msg.contains("network") || msg.contains("internet") || msg.contains("offline") {
            return "네트워크 연결을 확인해주세요."
        }
        return "구절을 가져오지 못했어요. 잠시 후 다시 시도해주세요."
    }

    private func loadRecentSearches() {
        let saved = UserDefaults.standard.stringArray(forKey: Self.recentSearchesKey) ?? []
        state.recentSearches = saved
    }

    private func addToRecentSearches(_ ref: String) {
        var searches = state.recentSearches.filter { $0 != ref }
        searches.insert(ref, at: 0)
        if searches.count > Self.maxRecentCount {
            searches = Array(searches.prefix(Self.maxRecentCount))
        }
        state.recentSearches = searches
        UserDefaults.standard.set(searches, forKey: Self.recentSearchesKey)
    }
}
