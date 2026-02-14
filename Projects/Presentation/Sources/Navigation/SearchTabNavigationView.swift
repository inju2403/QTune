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
    @Binding var path: NavigationPath

    let detailViewModelFactory: (QuietTime) -> QTDetailViewModel
    let editorViewModelFactory: () -> QTEditorViewModel
    let profileEditViewModelFactory: (UserProfile?) -> ProfileEditViewModel
    let getUserProfileUseCase: GetUserProfileUseCase

    public init(
        qtListViewModel: QTListViewModel,
        userProfile: Binding<UserProfile?>,
        searchText: Binding<String>,
        isSearchPresented: Binding<Bool>,
        path: Binding<NavigationPath>,
        detailViewModelFactory: @escaping (QuietTime) -> QTDetailViewModel,
        editorViewModelFactory: @escaping () -> QTEditorViewModel,
        profileEditViewModelFactory: @escaping (UserProfile?) -> ProfileEditViewModel,
        getUserProfileUseCase: GetUserProfileUseCase
    ) {
        self.qtListViewModel = qtListViewModel
        self._userProfile = userProfile
        self._searchText = searchText
        self._isSearchPresented = isSearchPresented
        self._path = path
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
        }
        .searchable(
            text: $searchText,
            isPresented: $isSearchPresented,
            placement: .automatic,
            prompt: "QT 기록을 검색해보세요."
        )
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
    }
}
