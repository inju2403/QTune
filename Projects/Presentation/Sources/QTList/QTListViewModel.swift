//
//  QTListViewModel.swift
//  Presentation
//
//  Created by 이승주 on 10/12/25.
//

import Foundation
import SwiftUI
import Domain

/// QT 리스트 화면 ViewModel
public final class QTListViewModel: ObservableObject {
    // MARK: - Published State
    @Published public var searchText: String = ""
    @Published public var selectedFilter: FilterType = .all
    @Published public var selectedSort: SortType = .newest
    @Published public var showDeleteAlert = false
    @Published public var qtToDelete: QuietTime?
    @Published public var qtList: [QuietTime] = []
    @Published public var isLoading = false

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
        self.fetchQTListUseCase = fetchQTListUseCase
        self.toggleFavoriteUseCase = toggleFavoriteUseCase
        self.deleteQTUseCase = deleteQTUseCase
        self.session = session
    }

    // MARK: - Filter Types
    public enum FilterType: String, CaseIterable {
        case all = "전체"
        case favorite = "즐겨찾기"
        case soap = "S.O.A.P"
        case acts = "A.C.T.S"

        var displayName: String { rawValue }
    }

    // MARK: - Sort Types
    public enum SortType: String, CaseIterable {
        case newest = "최신순"
        case oldest = "오래된순"

        var displayName: String { rawValue }
    }

    // MARK: - Actions
    public func load() async {
        await MainActor.run { isLoading = true }

        do {
            let query = QTQuery(limit: 100, offset: 0)
            let list = try await fetchQTListUseCase.execute(query: query, session: session)

            await MainActor.run {
                qtList = list
                isLoading = false
            }
        } catch {
            await MainActor.run {
                qtList = []
                isLoading = false
            }
        }
    }

    public func toggleFavorite(_ qt: QuietTime) async {
        do {
            _ = try await toggleFavoriteUseCase.execute(id: qt.id, session: session)
            await load()  // 리로드
        } catch {
            // 실패 처리 (선택)
        }
    }

    public func confirmDelete(_ qt: QuietTime) {
        qtToDelete = qt
        showDeleteAlert = true
    }

    public func deleteQT() async {
        guard let qt = qtToDelete else { return }

        do {
            try await deleteQTUseCase.execute(id: qt.id, session: session)
            await load()  // 리로드
            await MainActor.run {
                qtToDelete = nil
                showDeleteAlert = false
            }
        } catch {
            await MainActor.run {
                showDeleteAlert = false
            }
        }
    }

    public func cancelDelete() {
        qtToDelete = nil
        showDeleteAlert = false
    }

    // MARK: - Filter Logic
    public var filteredAndSortedList: [QuietTime] {
        var filtered = qtList

        // 필터 적용
        switch selectedFilter {
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
        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
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
        switch selectedSort {
        case .newest:
            filtered.sort { $0.date > $1.date }
        case .oldest:
            filtered.sort { $0.date < $1.date }
        }

        return filtered
    }
}
