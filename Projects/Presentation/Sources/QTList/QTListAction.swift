//
//  QTListAction.swift
//  Presentation
//
//  Created by 이승주 on 10/12/25.
//

import Foundation
import Domain

/// QT 리스트 화면 Action
public enum QTListAction: Equatable {
    case load
    case loadMore
    case updateSearchText(String, isSearchMode: Bool = false)
    case selectFilter(QTListState.FilterType)
    case selectSort(QTListState.SortType)
    case toggleFavorite(QuietTime)
    case confirmDelete(QuietTime)
    case deleteQT
    case cancelDelete
    case insertAtTop(QuietTime)
    case updateItem(QuietTime)
    case removeItem(UUID)
    case clearNewlyAddedId

    // MARK: - Calendar Actions
    case loadCalendar            // 달력 데이터 로드
    case changeMonth(Int)        // 월 이동 (-1: 이전, +1: 다음)
    case selectDate(Date?)       // 날짜 선택 (nil이면 전체)
    case toggleCalendar          // 달력 펼침/접기
}
