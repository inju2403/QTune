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

    // MARK: - Debounce
    private var searchTask: Task<Void, Never>?

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

        case .loadMore:
            Task { await loadMore() }

        case .updateSearchText(let text):
            let previousText = state.searchText
            state.searchText = text

            // 텍스트가 실제로 변경되지 않았으면 아무것도 안 함
            guard previousText != text else { return }

            // 이전 검색 Task 취소
            searchTask?.cancel()

            // 검색어가 비어있으면 즉시 로드 (debounce 없이)
            if text.isEmpty {
                Task { await load() }
            } else {
                // 200ms 후 검색 실행 (debounce)
                searchTask = Task {
                    try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
                    guard !Task.isCancelled else { return }
                    await load()
                }
            }

        case .selectFilter(let filter):
            state.selectedFilter = filter
            // 필터 변경 시 새로 로드
            Task { await load() }

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
        // 이미 로딩 중이면 리턴 (race condition 방지)
        guard !state.isLoading else {
            print("⚠️ [QTListViewModel] Already loading, skipping duplicate load request")
            return
        }

        state.isLoading = true
        state.currentPage = 0

        do {
            // 검색어와 필터를 Query에 포함
            let searchText = state.searchText.isEmpty ? nil : state.searchText
            let isFavorite: Bool? = state.selectedFilter == .favorite ? true : nil

            let query = QTQuery(
                isFavorite: isFavorite,
                searchText: searchText,
                limit: 20,
                offset: 0
            )
            let list = try await fetchQTListUseCase.execute(query: query, session: session)

            await MainActor.run {
                state.qtList = list
                state.hasMoreData = list.count == 20
                state.isLoading = false
            }
        } catch {
            await MainActor.run {
                state.qtList = []
                state.hasMoreData = false
                state.isLoading = false
            }
            print("❌ [QTListViewModel] Failed to load QT list: \(error)")
        }
    }

    private func loadMore() async {
        // 이미 로딩 중이거나 더 이상 데이터가 없으면 리턴
        guard !state.isLoadingMore && !state.isLoading && state.hasMoreData else {
            return
        }

        state.isLoadingMore = true
        let nextPage = state.currentPage + 1

        do {
            // 검색어와 필터를 Query에 포함
            let searchText = state.searchText.isEmpty ? nil : state.searchText
            let isFavorite: Bool? = state.selectedFilter == .favorite ? true : nil

            let query = QTQuery(
                isFavorite: isFavorite,
                searchText: searchText,
                limit: 20,
                offset: nextPage * 20
            )
            let newList = try await fetchQTListUseCase.execute(query: query, session: session)

            await MainActor.run {
                state.qtList.append(contentsOf: newList)
                state.currentPage = nextPage
                state.hasMoreData = newList.count == 20
                state.isLoadingMore = false
            }
        } catch {
            await MainActor.run {
                state.isLoadingMore = false
            }
            print("❌ [QTListViewModel] Failed to load more QT list: \(error)")
        }
    }

    private func toggleFavorite(_ qt: QuietTime) async {
        // Optimistic update: 로컬 state 먼저 업데이트
        if let index = state.qtList.firstIndex(where: { $0.id == qt.id }) {
            var updatedQT = state.qtList[index]
            updatedQT.isFavorite.toggle()

            await MainActor.run {
                state.qtList[index] = updatedQT
            }
        }

        // 백그라운드에서 서버 업데이트
        do {
            _ = try await toggleFavoriteUseCase.execute(id: qt.id, session: session)
        } catch {
            // 실패 시 롤백
            if let index = state.qtList.firstIndex(where: { $0.id == qt.id }) {
                var revertedQT = state.qtList[index]
                revertedQT.isFavorite.toggle()

                await MainActor.run {
                    state.qtList[index] = revertedQT
                }
            }
            print("❌ [QTListViewModel] Failed to toggle favorite: \(error)")
        }
    }

    private func deleteQT() async {
        guard let qt = state.qtToDelete else { return }

        do {
            try await deleteQTUseCase.execute(id: qt.id, session: session)

            await MainActor.run {
                NotificationCenter.default.post(name: .qtDidChange, object: nil)
                state.qtList.removeAll { $0.id == qt.id }
                state.qtToDelete = nil
                state.showDeleteAlert = false
            }
        } catch {
            await MainActor.run {
                state.showDeleteAlert = false
            }
            print("❌ [QTListViewModel] Failed to delete QT: \(error)")
        }
    }

    // MARK: - Filter Logic
    public var filteredAndSortedList: [QuietTime] {
        var filtered = state.qtList

        // 템플릿 필터는 로컬에서 처리 (서버에서는 검색/즐겨찾기만 처리)
        switch state.selectedFilter {
        case .all, .favorite:
            break
        case .soap:
            filtered = filtered.filter { $0.template == "SOAP" }
        case .acts:
            filtered = filtered.filter { $0.template == "ACTS" }
        }

        // 정렬 적용 (로컬)
        switch state.selectedSort {
        case .newest:
            filtered.sort { $0.date > $1.date }
        case .oldest:
            filtered.sort { $0.date < $1.date }
        }

        return filtered
    }
}
