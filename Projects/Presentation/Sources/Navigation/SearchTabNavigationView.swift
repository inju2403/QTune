//
//  SearchTabNavigationView.swift
//  Presentation
//
//  Created by 이승주 on 1/21/26.
//

import SwiftUI
import Domain

/// 검색 탭 전용 NavigationStack (searchable을 루트에만 적용)
public struct SearchTabNavigationView: View {

    let qtListViewModel: QTListViewModel
    @Binding var userProfile: UserProfile?
    @Binding var searchText: String
    @Binding var isSearchPresented: Bool

    let detailViewModelFactory: (QuietTime) -> QTDetailViewModel
    let editorViewModelFactory: () -> QTEditorViewModel
    let profileEditViewModelFactory: (UserProfile?) -> ProfileEditViewModel
    let getUserProfileUseCase: GetUserProfileUseCase

    @State private var path = NavigationPath()
    @FocusState private var isSearchFieldFocused: Bool
    @State private var forceRefresh = false

    public init(
        qtListViewModel: QTListViewModel,
        userProfile: Binding<UserProfile?>,
        searchText: Binding<String>,
        isSearchPresented: Binding<Bool>,
        detailViewModelFactory: @escaping (QuietTime) -> QTDetailViewModel,
        editorViewModelFactory: @escaping () -> QTEditorViewModel,
        profileEditViewModelFactory: @escaping (UserProfile?) -> ProfileEditViewModel,
        getUserProfileUseCase: GetUserProfileUseCase
    ) {
        self.qtListViewModel = qtListViewModel
        self._userProfile = userProfile
        self._searchText = searchText
        self._isSearchPresented = isSearchPresented
        self.detailViewModelFactory = detailViewModelFactory
        self.editorViewModelFactory = editorViewModelFactory
        self.profileEditViewModelFactory = profileEditViewModelFactory
        self.getUserProfileUseCase = getUserProfileUseCase
    }

    public var body: some View {
        NavigationStack(path: $path) {
            QTSearchListView(
                viewModel: qtListViewModel,
                userProfile: $userProfile,
                path: $path,
                searchText: $searchText,
                isSearchPresented: $isSearchPresented,
                detailViewModelFactory: detailViewModelFactory,
                editorViewModelFactory: editorViewModelFactory,
                profileEditViewModelFactory: profileEditViewModelFactory,
                getUserProfileUseCase: getUserProfileUseCase
            )
            .searchable(
                text: $searchText,
                isPresented: $isSearchPresented,
                placement: UIDevice.current.userInterfaceIdiom == .pad
                    ? .toolbar  // iPad에서는 toolbar placement 시도
                    : .automatic,
                prompt: "QT 기록을 검색해보세요."
            )
            .searchSuggestions {
                // 빈 suggestion view로 검색창 활성화 유도
                if UIDevice.current.userInterfaceIdiom == .pad && searchText.isEmpty && isSearchPresented {
                    Text("검색어를 입력하세요")
                        .foregroundStyle(.secondary)
                }
            }
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .onChange(of: isSearchPresented) { _, newValue in
                if newValue && UIDevice.current.userInterfaceIdiom == .pad {
                    // iPad에서 검색이 활성화되면 강제 refresh로 UI 업데이트
                    forceRefresh.toggle()
                }
            }
            // 숨겨진 Toggle로 강제 UI 재렌더링 (iOS 17 workaround)
            .background(
                Toggle("", isOn: $forceRefresh)
                    .hidden()
            )
        }
    }
}
