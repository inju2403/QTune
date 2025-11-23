//
//  QTListViewModel.swift
//  Presentation
//
//  Created by 이승주 on 10/12/25.
//

import Foundation
import Domain

/// QT 리스트 화면 ViewModel
@Observable
public final class QTListViewModel {
    // MARK: - State
    public private(set) var state: QTListState

    // MARK: - Dependencies
    private let fetchQTListUseCase: FetchQTListUseCase
    private let toggleFavoriteUseCase: ToggleFavoriteUseCase
    private let deleteQTUseCase: DeleteQTUseCase
    private let session: UserSession

    // MARK: - Init
    public init(
        fetchQTListUseCase: FetchQTListUseCase,
        toggleFavoriteUseCase: ToggleFavoriteUseCase,
        deleteQTUseCase: DeleteQTUseCase,
        session: UserSession
    ) {
        self.state = QTListState()
        self.fetchQTListUseCase = fetchQTListUseCase
        self.toggleFavoriteUseCase = toggleFavoriteUseCase
        self.deleteQTUseCase = deleteQTUseCase
        self.session = session
    }

    // MARK: - Send Action
    public func send(_ action: QTListAction) {
        switch action {
        case .load:
            Task { await load() }

        case .updateSearchText(let text):
            state.searchText = text

        case .selectFilter(let filter):
            state.selectedFilter = filter

        case .selectSort(let sort):
            state.selectedSort = sort

        case .toggleFavorite(let qt):
            Task { await toggleFavorite(qt) }

        case .confirmDelete(let qt):
            state.qtToDelete = qt
            state.showDeleteAlert = true

        case .deleteQT:
            Task { await deleteQT() }

        case .cancelDelete:
            state.qtToDelete = nil
            state.showDeleteAlert = false
        }
    }

    // MARK: - Actions
    private func load() async {
        state.isLoading = true

        do {
            let query = QTQuery(limit: 100, offset: 0)
            let list = try await fetchQTListUseCase.execute(query: query, session: session)

            state.qtList = list
            state.isLoading = false
        } catch {
            state.qtList = []
            state.isLoading = false
        }
    }

    private func toggleFavorite(_ qt: QuietTime) async {
        do {
            _ = try await toggleFavoriteUseCase.execute(id: qt.id, session: session)
            await load()  // 리로드
        } catch {
            // 실패 처리 (선택)
        }
    }

    private func deleteQT() async {
        guard let qt = state.qtToDelete else { return }

        do {
            try await deleteQTUseCase.execute(id: qt.id, session: session)
            await load()  // 리로드
            state.qtToDelete = nil
            state.showDeleteAlert = false
        } catch {
            state.showDeleteAlert = false
        }
    }

    // MARK: - Filter Logic
    public var filteredAndSortedList: [QuietTime] {
        var filtered = state.qtList

        // 필터 적용
        switch state.selectedFilter {
        case .all:
            break
        case .favorite:
            filtered = filtered.filter { $0.isFavorite }
        case .soap:
            filtered = filtered.filter { $0.template == "SOAP" }
        case .acts:
            filtered = filtered.filter { $0.template == "ACTS" }
        }

        // 검색 적용
        if !state.searchText.isEmpty {
            let searchLower = state.searchText.lowercased()
            filtered = filtered.filter { qt in
                let matchesVerse = qt.verse.id.lowercased().contains(searchLower)
                let matchesKorean = (qt.korean ?? "").lowercased().contains(searchLower)
                let matchesReason = (qt.rationale ?? "").lowercased().contains(searchLower)
                let matchesTags = qt.tags.contains { $0.lowercased().contains(searchLower) }

                var matchesTemplate = false
                if qt.template == "SOAP" {
                    matchesTemplate = [qt.soapObservation, qt.soapApplication, qt.soapPrayer]
                        .compactMap { $0 }
                        .contains { $0.lowercased().contains(searchLower) }
                } else {
                    matchesTemplate = [qt.actsAdoration, qt.actsConfession, qt.actsThanksgiving, qt.actsSupplication]
                        .compactMap { $0 }
                        .contains { $0.lowercased().contains(searchLower) }
                }

                return matchesVerse || matchesKorean || matchesReason || matchesTags || matchesTemplate
            }
        }

        // 정렬 적용
        switch state.selectedSort {
        case .newest:
            filtered.sort { $0.date > $1.date }
        case .oldest:
            filtered.sort { $0.date < $1.date }
        }

        return filtered
    }
}
