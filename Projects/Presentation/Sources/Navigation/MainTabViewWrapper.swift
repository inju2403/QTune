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
    let profileEditViewModelFactory: (UserProfile?) -> ProfileEditViewModel
    let generateVerseUseCase: GenerateVerseUseCase
    let commitQTUseCase: CommitQTUseCase
    let getUserProfileUseCase: GetUserProfileUseCase
    let saveUserProfileUseCase: SaveUserProfileUseCase
    let session: UserSession

    @State private var selectedTab = 0
    @Binding var userProfile: UserProfile?
    @State private var isRequestVerseLoading = false

    public init(
        qtListViewModel: QTListViewModel,
        detailViewModelFactory: @escaping (QuietTime) -> QTDetailViewModel,
        editorViewModelFactory: @escaping () -> QTEditorViewModel,
        profileEditViewModelFactory: @escaping (UserProfile?) -> ProfileEditViewModel,
        generateVerseUseCase: GenerateVerseUseCase,
        commitQTUseCase: CommitQTUseCase,
        getUserProfileUseCase: GetUserProfileUseCase,
        saveUserProfileUseCase: SaveUserProfileUseCase,
        session: UserSession,
        userProfile: Binding<UserProfile?>
    ) {
        self.qtListViewModel = qtListViewModel
        self.detailViewModelFactory = detailViewModelFactory
        self.editorViewModelFactory = editorViewModelFactory
        self.profileEditViewModelFactory = profileEditViewModelFactory
        self.generateVerseUseCase = generateVerseUseCase
        self.commitQTUseCase = commitQTUseCase
        self.getUserProfileUseCase = getUserProfileUseCase
        self.saveUserProfileUseCase = saveUserProfileUseCase
        self.session = session
        self._userProfile = userProfile
    }

    public var body: some View {
        tabViewContent
    }

    @ViewBuilder
    private var tabViewContent: some View {
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
                    onNavigateToRecordTab: onNavigateToRecordTab,
                    onNavigateToMyPage: {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            selectedTab = 2
                        }
                    },
                    isLoading: $isRequestVerseLoading,
                    userProfile: $userProfile
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
                userProfile: $userProfile,
                detailViewModelFactory: detailViewModelFactory,
                editorViewModelFactory: editorViewModelFactory,
                profileEditViewModelFactory: profileEditViewModelFactory,
                getUserProfileUseCase: getUserProfileUseCase,
                onNavigateToMyPage: {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        selectedTab = 2
                    }
                }
            )
            .tabItem {
                Label("기록", systemImage: "book.closed")
            }
            .tag(1)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))

            MyPageView(
                viewModel: MyPageViewModel(),
                userProfile: $userProfile,
                profileEditViewModelFactory: profileEditViewModelFactory,
                getUserProfileUseCase: getUserProfileUseCase
            )
            .tabItem {
                Label("마이페이지", systemImage: "person.circle")
            }
            .tag(2)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
        }
        .allowsHitTesting(!isRequestVerseLoading)
        .accentColor(DS.Color.mocha)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: selectedTab)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(DS.Color.bgBot)

            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(DS.Color.lightBrown)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor(DS.Color.lightBrown)
            ]

            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(DS.Color.mocha)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(DS.Color.mocha)
            ]

            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
