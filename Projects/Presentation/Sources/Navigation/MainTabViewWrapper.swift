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
    @State private var searchText = ""
    @State private var previousTab = 0
    @State private var isSearchPresented = false

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
        if #available(iOS 26.0, *) {
            // iOS 26+ Liquid Glass Tab Bar
            liquidGlassTabView
        } else {
            // iOS 18-25 fallback
            legacyTabView
        }
    }

    @available(iOS 26.0, *)
    @ViewBuilder
    private var liquidGlassTabView: some View {
        TabView(selection: $selectedTab) {
            Tab("오늘의 말씀", systemImage: "sparkles", value: 0) {
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
            }

            Tab("기록", systemImage: "book.closed", value: 1) {
                RootNavigationView(
                    onNavigateToRecordTab: {
                        // 이미 기록 탭이므로 아무것도 안 함
                    }
                ) { path, _ in
                    QTListView(
                        viewModel: qtListViewModel,
                        userProfile: $userProfile,
                        path: path,
                        detailViewModelFactory: detailViewModelFactory,
                        editorViewModelFactory: editorViewModelFactory,
                        profileEditViewModelFactory: profileEditViewModelFactory,
                        getUserProfileUseCase: getUserProfileUseCase,
                        onNavigateToMyPage: {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                selectedTab = 2
                            }
                        },
                        hideSearchBar: true
                    )
                }
            }

            Tab("마이페이지", systemImage: "person.circle", value: 2) {
                MyPageView(
                    viewModel: MyPageViewModel(),
                    userProfile: $userProfile,
                    profileEditViewModelFactory: profileEditViewModelFactory,
                    getUserProfileUseCase: getUserProfileUseCase
                )
            }

            Tab(value: 3, role: .search) {
                SearchTabNavigationView(
                    qtListViewModel: qtListViewModel,
                    userProfile: $userProfile,
                    searchText: $searchText,
                    isSearchPresented: $isSearchPresented,
                    detailViewModelFactory: detailViewModelFactory,
                    editorViewModelFactory: editorViewModelFactory,
                    profileEditViewModelFactory: profileEditViewModelFactory,
                    getUserProfileUseCase: getUserProfileUseCase,
                    onNavigateToMyPage: {
                        selectedTab = 2
                        isSearchPresented = false
                        searchText = ""
                    }
                )
                .onChange(of: isSearchPresented) { _, presented in
                    if !presented && selectedTab == 3 && searchText.isEmpty {
                        selectedTab = previousTab
                    }
                }
            }
        }
        .allowsHitTesting(!isRequestVerseLoading)
        .tint(DS.Color.mocha)
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == 3 {
                previousTab = oldValue
                // isSearchPresented는 QTSearchListView 내부에서 관리
            } else {
                isSearchPresented = false
            }
        }
        .onAppear {
            UITabBar.appearance().itemPositioning = .centered
            UITabBar.appearance().itemSpacing = 8
        }
    }

    @ViewBuilder
    private var legacyTabView: some View {
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

            RootNavigationView(
                onNavigateToRecordTab: {
                    // 이미 기록 탭이므로 아무것도 안 함
                }
            ) { path, _ in
                QTListView(
                    viewModel: qtListViewModel,
                    userProfile: $userProfile,
                    path: path,
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
            }
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
