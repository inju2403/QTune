//
//  QTListState.swift
//  Presentation
//
//  Created by 이승주 on 10/12/25.
//

import Foundation
import Domain

/// QT 달력에서 하루의 상태
public enum QTDayStatus: Equatable {
    case none           // 아무것도 안 한 날
    case verseOnly      // 말씀 추천만 받음 (draft)
    case completed      // QT 완료 (committed)
}

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

    // MARK: - Calendar State
    public var displayedMonth: Date   // 현재 표시 중인 월 (1일 기준)
    public var selectedDate: Date?    // 선택된 날짜 (nil이면 전체)
    public var calendarData: [String: QTDayStatus]  // "yyyy-MM-dd" → 상태
    public var currentStreak: Int     // 연속 QT 일수
    public var monthlyCount: Int      // 이번 달 QT 횟수
    public var isCalendarExpanded: Bool  // 달력 펼침 상태

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
        newlyAddedQTId: UUID? = nil,
        displayedMonth: Date = Date(),
        selectedDate: Date? = nil,
        calendarData: [String: QTDayStatus] = [:],
        currentStreak: Int = 0,
        monthlyCount: Int = 0,
        isCalendarExpanded: Bool = true
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
        self.displayedMonth = displayedMonth
        self.selectedDate = selectedDate
        self.calendarData = calendarData
        self.currentStreak = currentStreak
        self.monthlyCount = monthlyCount
        self.isCalendarExpanded = isCalendarExpanded
    }

    // MARK: - Filter Types
    public enum FilterType: String, CaseIterable, Equatable {
        case all = "전체"
        case favorite = "즐겨찾기"
        case soap = "S.O.A.P"
        case acts = "A.C.T.S"
        case free = "자유 묵상"

        public var displayName: String { rawValue }
    }

    // MARK: - Sort Types
    public enum SortType: String, CaseIterable, Equatable {
        case newest = "최신순"
        case oldest = "오래된순"

        public var displayName: String { rawValue }
    }
}
