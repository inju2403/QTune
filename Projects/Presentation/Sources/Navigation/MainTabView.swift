//
//  MainTabView.swift
//  Presentation
//
//  Created by 이승주 on 10/12/25.
//

import SwiftUI
import Domain

public struct MainTabView<RequestContent: View>: View {
    let requestContent: () -> RequestContent
    let qtListViewModel: QTListViewModel
    let detailViewModelFactory: (QuietTime) -> QTDetailViewModel
    let editorViewModelFactory: () -> QTEditorViewModel

    public init(
        qtListViewModel: QTListViewModel,
        detailViewModelFactory: @escaping (QuietTime) -> QTDetailViewModel,
        editorViewModelFactory: @escaping () -> QTEditorViewModel,
        @ViewBuilder requestContent: @escaping () -> RequestContent
    ) {
        self.qtListViewModel = qtListViewModel
        self.detailViewModelFactory = detailViewModelFactory
        self.editorViewModelFactory = editorViewModelFactory
        self.requestContent = requestContent
    }

    public var body: some View {
        TabView {
            requestContent()
                .tabItem {
                    Label("오늘의 말씀", systemImage: "sparkles")
                }

            QTListView(
                viewModel: qtListViewModel,
                detailViewModelFactory: detailViewModelFactory,
                editorViewModelFactory: editorViewModelFactory
            )
            .tabItem {
                Label("기록", systemImage: "book.closed")
            }
        }
    }
}
