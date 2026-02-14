//
//  QTListState.swift
//  Presentation
//
//  Created by 이승주 on 10/12/25.
//

import Foundation
import Domain

/// QT 리스트 화면 State
public struct QTListState: Equatable {
    public var searchText: String
    public var selectedFilter: FilterType
    public var selectedSort: SortType
    public var showDeleteAlert: Bool
    public var qtToDelete: QuietTime?
    public var qtList: [QuietTime]
    public var isLoading: Bool
    public var isLoadingMore: Bool
    public var hasMoreData: Bool
    public var currentPage: Int
    public var lastLoadTime: Date?
    public var newlyAddedQTId: UUID?  // 새로 추가된 QT ID (스크롤용)

    public init(
        searchText: String = "",
        selectedFilter: FilterType = .all,
        selectedSort: SortType = .newest,
        showDeleteAlert: Bool = false,
        qtToDelete: QuietTime? = nil,
        qtList: [QuietTime] = [],
        isLoading: Bool = false,
        isLoadingMore: Bool = false,
        hasMoreData: Bool = true,
        currentPage: Int = 0,
        lastLoadTime: Date? = nil,
        newlyAddedQTId: UUID? = nil
    ) {
        self.searchText = searchText
        self.selectedFilter = selectedFilter
        self.selectedSort = selectedSort
        self.showDeleteAlert = showDeleteAlert
        self.qtToDelete = qtToDelete
        self.qtList = qtList
        self.isLoading = isLoading
        self.isLoadingMore = isLoadingMore
        self.hasMoreData = hasMoreData
        self.currentPage = currentPage
        self.lastLoadTime = lastLoadTime
        self.newlyAddedQTId = newlyAddedQTId
    }

    // MARK: - Filter Types
    public enum FilterType: String, CaseIterable, Equatable {
        case all = "전체"
        case favorite = "즐겨찾기"
        case soap = "S.O.A.P"
        case acts = "A.C.T.S"

        public var displayName: String { rawValue }
    }

    // MARK: - Sort Types
    public enum SortType: String, CaseIterable, Equatable {
        case newest = "최신순"
        case oldest = "오래된순"

        public var displayName: String { rawValue }
    }
}
