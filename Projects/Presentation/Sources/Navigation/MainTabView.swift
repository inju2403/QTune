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

    @State private var selectedTab = 0

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
        TabView(selection: $selectedTab) {
            requestContent()
                .tabItem {
                    Label("오늘의 말씀", systemImage: "sparkles")
                }
                .tag(0)

            QTListView(
                viewModel: qtListViewModel,
                detailViewModelFactory: detailViewModelFactory,
                editorViewModelFactory: editorViewModelFactory
            )
            .tabItem {
                Label("기록", systemImage: "book.closed")
            }
            .tag(1)
        }
        .accentColor(DSColor.mocha)  // 탭 선택 색상을 모카 브라운으로 변경
        .onAppear {
            // 탭바 비선택 아이템 색상 설정
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(DSColor.card)

            // 비선택 아이템 색상
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(DSColor.lightBrown)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor(DSColor.lightBrown)
            ]

            // 선택된 아이템 색상
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(DSColor.mocha)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(DSColor.mocha)
            ]

            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
