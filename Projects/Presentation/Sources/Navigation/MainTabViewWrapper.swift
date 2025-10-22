//
//  MainTabViewWrapper.swift
//  Presentation
//
//  Created by 이승주 on 10/19/25.
//

import SwiftUI
import Domain

/// MainTabView와 RootNavigationView를 연결하는 래퍼
public struct MainTabViewWrapper: View {
    let qtListViewModel: QTListViewModel
    let detailViewModelFactory: (QuietTime) -> QTDetailViewModel
    let editorViewModelFactory: () -> QTEditorViewModel
    let generateVerseUseCase: GenerateVerseUseCase
    let commitQTUseCase: CommitQTUseCase
    let getUserProfileUseCase: GetUserProfileUseCase
    let saveUserProfileUseCase: SaveUserProfileUseCase
    let session: UserSession

    @State private var selectedTab = 0

    public init(
        qtListViewModel: QTListViewModel,
        detailViewModelFactory: @escaping (QuietTime) -> QTDetailViewModel,
        editorViewModelFactory: @escaping () -> QTEditorViewModel,
        generateVerseUseCase: GenerateVerseUseCase,
        commitQTUseCase: CommitQTUseCase,
        getUserProfileUseCase: GetUserProfileUseCase,
        saveUserProfileUseCase: SaveUserProfileUseCase,
        session: UserSession
    ) {
        self.qtListViewModel = qtListViewModel
        self.detailViewModelFactory = detailViewModelFactory
        self.editorViewModelFactory = editorViewModelFactory
        self.generateVerseUseCase = generateVerseUseCase
        self.commitQTUseCase = commitQTUseCase
        self.getUserProfileUseCase = getUserProfileUseCase
        self.saveUserProfileUseCase = saveUserProfileUseCase
        self.session = session
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            RootNavigationView(
                onNavigateToRecordTab: {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        selectedTab = 1
                    }
                }
            ) { path, onNavigateToRecordTab in
                RequestVerseView(
                    viewModel: RequestVerseViewModel(
                        generateVerseUseCase: generateVerseUseCase
                    ),
                    path: path,
                    commitQTUseCase: commitQTUseCase,
                    session: session,
                    getUserProfileUseCase: getUserProfileUseCase,
                    saveUserProfileUseCase: saveUserProfileUseCase,
                    onNavigateToRecordTab: onNavigateToRecordTab
                )
            }
            .tabItem {
                Label("오늘의 말씀", systemImage: "sparkles")
            }
            .tag(0)
            .transition(.asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
            ))

            QTListView(
                viewModel: qtListViewModel,
                detailViewModelFactory: detailViewModelFactory,
                editorViewModelFactory: editorViewModelFactory,
                getUserProfileUseCase: getUserProfileUseCase,
                saveUserProfileUseCase: saveUserProfileUseCase
            )
            .tabItem {
                Label("기록", systemImage: "book.closed")
            }
            .tag(1)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
        }
        .accentColor(DSColor.mocha)
        .animation(.easeInOut(duration: 0.35), value: selectedTab)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(DSColor.card)

            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(DSColor.lightBrown)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor(DSColor.lightBrown)
            ]

            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(DSColor.mocha)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(DSColor.mocha)
            ]

            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
