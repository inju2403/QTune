//
//  QTSearchListView.swift
//  Presentation
//
//  Created by 이승주 on 1/21/26.
//

import SwiftUI
import Domain

/// iOS 26 검색 탭 전용 뷰 (시스템 searchable 연동)
public struct QTSearchListView: View {

    // MARK: - State
    @State private var viewModel: QTListViewModel
    @Binding var userProfile: UserProfile?
    @Binding var path: NavigationPath
    @Binding var searchText: String
    @Binding var isSearchPresented: Bool

    @State private var scrollPosition: UUID?

    // MARK: - Dependencies
    let detailViewModelFactory: (QuietTime) -> QTDetailViewModel
    let editorViewModelFactory: () -> QTEditorViewModel
    let profileEditViewModelFactory: (UserProfile?) -> ProfileEditViewModel
    let getUserProfileUseCase: GetUserProfileUseCase

    // MARK: - Init
    public init(
        viewModel: QTListViewModel,
        userProfile: Binding<UserProfile?>,
        path: Binding<NavigationPath>,
        searchText: Binding<String>,
        isSearchPresented: Binding<Bool>,
        detailViewModelFactory: @escaping (QuietTime) -> QTDetailViewModel,
        editorViewModelFactory: @escaping () -> QTEditorViewModel,
        profileEditViewModelFactory: @escaping (UserProfile?) -> ProfileEditViewModel,
        getUserProfileUseCase: GetUserProfileUseCase
    ) {
        _viewModel = State(wrappedValue: viewModel)
        _userProfile = userProfile
        _path = path
        _searchText = searchText
        _isSearchPresented = isSearchPresented

        self.detailViewModelFactory = detailViewModelFactory
        self.editorViewModelFactory = editorViewModelFactory
        self.profileEditViewModelFactory = profileEditViewModelFactory
        self.getUserProfileUseCase = getUserProfileUseCase
    }

    // MARK: - Body
    public var body: some View {
        ZStack {
            CrossSunsetBackground()

            List {
                // 검색어가 있을 때만 리스트 표시
                if searchText.isEmpty {
                    emptyStateView()
                        .frame(minHeight: 400)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())

                } else if viewModel.state.isLoading {
                    VStack {
                        Spacer().frame(height: 100)
                        ProgressView()
                            .tint(DS.Color.gold)
                            .controlSize(.large)
                        Spacer().frame(height: 100)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())

                } else if viewModel.filteredAndSortedList.isEmpty {
                    emptyStateView()
                        .frame(minHeight: 400)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())

                } else {
                    ForEach(viewModel.filteredAndSortedList, id: \.id) { qt in
                        entryCell(qt)
                            .id(qt.id)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                path.append(QTSearchRoute.detail(qt))
                            }
                            .onAppear {
                                scrollPosition = qt.id

                                if let index = viewModel.filteredAndSortedList.firstIndex(where: { $0.id == qt.id }),
                                   index >= viewModel.filteredAndSortedList.count - 5 {
                                    viewModel.send(.loadMore)
                                }
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(
                                EdgeInsets(
                                    top: DS.Spacing.m/2,
                                    leading: DS.Spacing.l,
                                    bottom: DS.Spacing.m/2,
                                    trailing: DS.Spacing.l
                                )
                            )
                    }

                    if viewModel.state.isLoadingMore {
                        HStack {
                            Spacer()
                            ProgressView()
                                .tint(DS.Color.gold)
                            Spacer()
                        }
                        .frame(height: 60)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollPosition(id: $scrollPosition, anchor: .center)
        }
        .navigationBarHidden(true)
        .onAppear {
            // 검색 모드로 초기화
            viewModel.send(.updateSearchText(searchText, isSearchMode: true))
            // 검색 화면에서만 검색바 표시
            isSearchPresented = true
        }
        .onChange(of: searchText) { _, newValue in
            viewModel.send(.updateSearchText(newValue, isSearchMode: true))
        }
        .onReceive(NotificationCenter.default.publisher(for: .qtDidChange)) { _ in
            // 검색 결과 갱신 (검색어가 있을 때만)
            if !searchText.isEmpty {
                viewModel.send(.load)
            }
        }
        .alert("기록 삭제", isPresented: Binding(
            get: { viewModel.state.showDeleteAlert },
            set: { _ in }
        )) {
            Button("취소", role: .cancel) {
                viewModel.send(.cancelDelete)
            }
            Button("삭제", role: .destructive) {
                viewModel.send(.deleteQT)
            }
        } message: {
            Text("이 기록을 삭제할까요? 이 작업은 되돌릴 수 없습니다.")
        }
        .navigationDestination(for: QTSearchRoute.self) { route in
            switch route {
            case .detail(let qt):
                QTDetailView(
                    viewModel: detailViewModelFactory(qt),
                    editorViewModelFactory: editorViewModelFactory
                )
                .navigationBarBackButtonHidden(false)
            }
        }
    }
}

// MARK: - Subviews
private extension QTSearchListView {

    @ViewBuilder
    func entryCell(_ qt: QuietTime) -> some View {
        SoftCard {
            VStack(alignment: .leading, spacing: DS.Spacing.l) {
                HStack(alignment: .top) {
                    Text(qt.verse.id)
                        .font(.system(size: 21, weight: .bold, design: .serif))
                        .foregroundStyle(DS.Color.deepCocoa)
                        .lineLimit(2)

                    Spacer()

                    Text(formattedDate(qt.date))
                        .font(DS.Font.caption())
                        .foregroundStyle(DS.Color.textSecondary)
                }

                if let summary = summaryText(qt), !summary.isEmpty {
                    Text(summary)
                        .font(.system(size: 15, weight: .regular, design: .default))
                        .foregroundStyle(DS.Color.textPrimary)
                        .lineLimit(4)
                        .lineSpacing(5)
                }

                HStack(spacing: DS.Spacing.s) {
                    Text(qt.template)
                        .font(DS.Font.caption(.medium))
                        .foregroundStyle(qt.template == "SOAP" ? DS.Color.olive : DS.Color.gold)
                        .padding(.horizontal, DS.Spacing.m)
                        .padding(.vertical, DS.Spacing.s)
                        .background(
                            qt.template == "SOAP"
                                ? DS.Color.olive.opacity(0.15)
                                : DS.Color.gold.opacity(0.15)
                        )
                        .clipShape(Capsule())

                    Spacer()

                    Button {
                        Haptics.tap()
                        viewModel.send(.toggleFavorite(qt))
                    } label: {
                        Image(systemName: qt.isFavorite ? "star.fill" : "star")
                            .foregroundStyle(qt.isFavorite ? DS.Color.gold : DS.Color.textSecondary)
                            .font(.system(size: 20))
                            .padding(8)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                }
            }
            .padding(DS.Spacing.xl)
        }
    }

    @ViewBuilder
    func emptyStateView() -> some View {
        VStack(spacing: DS.Spacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(DS.Color.gold.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)

                Image(systemName: "magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundStyle(DS.Color.gold)
            }

            VStack(spacing: DS.Spacing.s) {
                Text(searchText.isEmpty ? "검색어를 입력해 주세요" : "검색된 내용이 없어요")
                    .font(DS.Font.titleM(.semibold))
                    .foregroundStyle(DS.Color.textPrimary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers
    func summaryText(_ qt: QuietTime) -> String? {
        if qt.template == "SOAP" {
            if let observation = qt.soapObservation?.trimmingCharacters(in: .whitespacesAndNewlines), !observation.isEmpty {
                return observation
            }
            if let application = qt.soapApplication?.trimmingCharacters(in: .whitespacesAndNewlines), !application.isEmpty {
                return application
            }
            if let prayer = qt.soapPrayer?.trimmingCharacters(in: .whitespacesAndNewlines), !prayer.isEmpty {
                return prayer
            }
        } else {
            if let adoration = qt.actsAdoration?.trimmingCharacters(in: .whitespacesAndNewlines), !adoration.isEmpty {
                return adoration
            }
            if let confession = qt.actsConfession?.trimmingCharacters(in: .whitespacesAndNewlines), !confession.isEmpty {
                return confession
            }
            if let thanksgiving = qt.actsThanksgiving?.trimmingCharacters(in: .whitespacesAndNewlines), !thanksgiving.isEmpty {
                return thanksgiving
            }
            if let supplication = qt.actsSupplication?.trimmingCharacters(in: .whitespacesAndNewlines), !supplication.isEmpty {
                return supplication
            }
        }
        return nil
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
}
