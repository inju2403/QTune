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
}
