//
//  QTListView.swift
//  Presentation
//
//  Created by 이승주 on 10/12/25.
//

import SwiftUI
import Domain

public struct QTListView: View {
    @State private var viewModel: QTListViewModel
    @Binding var userProfile: UserProfile?
    @State private var showProfileEdit = false

    let detailViewModelFactory: (QuietTime) -> QTDetailViewModel
    let editorViewModelFactory: () -> QTEditorViewModel
    let profileEditViewModelFactory: (UserProfile?) -> ProfileEditViewModel

    public init(
        viewModel: QTListViewModel,
        userProfile: Binding<UserProfile?>,
        detailViewModelFactory: @escaping (QuietTime) -> QTDetailViewModel,
        editorViewModelFactory: @escaping () -> QTEditorViewModel,
        profileEditViewModelFactory: @escaping (UserProfile?) -> ProfileEditViewModel
    ) {
        _viewModel = State(wrappedValue: viewModel)
        _userProfile = userProfile
        self.detailViewModelFactory = detailViewModelFactory
        self.editorViewModelFactory = editorViewModelFactory
        self.profileEditViewModelFactory = profileEditViewModelFactory
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                CrossSunsetBackground()

                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: []) {
                        // 검색바
                        searchBar()
                            .padding(.top, DS.Spacing.m)

                        // 필터 바
                        filterBar()

                        // 리스트
                        if viewModel.state.isLoading {
                            VStack {
                                Spacer()
                                    .frame(height: 100)
                                ProgressView()
                                    .tint(DS.Color.gold)
                                    .controlSize(.large)
                                Spacer()
                                    .frame(height: 100)
                            }
                        } else if viewModel.filteredAndSortedList.isEmpty {
                            emptyStateView()
                                .frame(minHeight: 400)
                        } else {
                            entriesContent()
                        }
                    }
                }
                .navigationDestination(for: QuietTime.self) { qt in
                    QTDetailView(
                        viewModel: detailViewModelFactory(qt),
                        editorViewModelFactory: editorViewModelFactory
                    )
                }
            }
            .onTapGesture {
                self.endTextEditing()
            }
            .navigationTitle("기록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ProfileHeaderView(profile: userProfile) {
                        Haptics.tap()
                        showProfileEdit = true
                    }
                }
            }
            .task {
                viewModel.send(.load)
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
            .sheet(isPresented: $showProfileEdit) {
                NavigationStack {
                    ProfileEditView(
                        viewModel: profileEditViewModelFactory(userProfile)
                    )
                }
            }
        }
    }
}

// MARK: - Subviews
private extension QTListView {
    @ViewBuilder
    func searchBar() -> some View {
        HStack(spacing: DS.Spacing.m) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(DS.Color.gold)
                .font(DS.Font.bodyL())

            TextField("말씀, 태그, 내용으로 검색", text: Binding(
                get: { viewModel.state.searchText },
                set: { viewModel.send(.updateSearchText($0)) }
            ))
                .font(DS.Font.bodyM())
                .foregroundStyle(DS.Color.textPrimary)
                .textFieldStyle(.plain)
                .autocapitalization(.none)
                .disableAutocorrection(true)

            if !viewModel.state.searchText.isEmpty {
                Button {
                    Haptics.tap()
                    withAnimation(Motion.appear) {
                        viewModel.send(.updateSearchText(""))
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(DS.Color.textSecondary)
                        .font(DS.Font.bodyL())
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(DS.Color.canvas.opacity(0.9))
        )
        .padding(.horizontal, DS.Spacing.l)
    }

    @ViewBuilder
    func filterBar() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Spacing.m) {
                // 필터
                Menu {
                    ForEach(QTListState.FilterType.allCases, id: \.self) { filter in
                        Button {
                            Haptics.tap()
                            viewModel.send(.selectFilter(filter))
                        } label: {
                            HStack {
                                Text(filter.displayName)
                                if viewModel.state.selectedFilter == filter {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    filterButton(text: viewModel.state.selectedFilter.displayName)
                }

                // 정렬
                Menu {
                    ForEach(QTListState.SortType.allCases, id: \.self) { sort in
                        Button {
                            Haptics.tap()
                            viewModel.send(.selectSort(sort))
                        } label: {
                            HStack {
                                Text(sort.displayName)
                                if viewModel.state.selectedSort == sort {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    sortButton(text: viewModel.state.selectedSort.displayName)
                }
            }
            .padding(.horizontal, DS.Spacing.l)
        }
        .padding(.top, DS.Spacing.m)
        .padding(.bottom, DS.Spacing.xs)
    }

    @ViewBuilder
    func filterButton(text: String) -> some View {
        ZStack {
            Capsule()
                .fill(DS.Color.canvas.opacity(0.9))
                .frame(width: 105, height: 38)

            HStack(spacing: DS.Spacing.xs) {
                Text(text)
                    .font(DS.Font.bodyM(.medium))
                    .foregroundStyle(DS.Color.textPrimary)

                Image(systemName: "chevron.down")
                    .font(DS.Font.caption())
                    .foregroundStyle(DS.Color.textPrimary)
            }
        }
        .frame(width: 105, height: 38)
    }

    @ViewBuilder
    func sortButton(text: String) -> some View {
        ZStack {
            Capsule()
                .fill(DS.Color.canvas.opacity(0.9))
                .frame(width: 105, height: 38)

            HStack(spacing: DS.Spacing.xs) {
                Text(text)
                    .font(DS.Font.bodyM(.medium))
                    .foregroundStyle(DS.Color.textPrimary)

                Image(systemName: "chevron.down")
                    .font(DS.Font.caption())
                    .foregroundStyle(DS.Color.textPrimary)
            }
        }
        .frame(width: 105, height: 38)
    }

    @ViewBuilder
    func entriesContent() -> some View {
        LazyVStack(spacing: DS.Spacing.m) {
            ForEach(Array(viewModel.filteredAndSortedList.enumerated()), id: \.element.id) { index, qt in
                NavigationLink(value: qt) {
                    entryCell(qt)
                }
                .buttonStyle(.plain)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .opacity
                ))
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.9)
                        .delay(Double(index) * 0.04),
                    value: viewModel.filteredAndSortedList.count
                )
            }
        }
        .padding(DS.Spacing.l)
        .padding(.top, DS.Spacing.xs)
    }

    @ViewBuilder
    func entryCell(_ qt: QuietTime) -> some View {
        SoftCard {
            VStack(alignment: .leading, spacing: DS.Spacing.l) {
                // 1행: 말씀 제목 (크고 두껍게) + 날짜
                HStack(alignment: .top) {
                    Text(qt.verse.id)
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .foregroundStyle(DS.Color.deepCocoa)
                        .lineLimit(2)

                    Spacer()

                    Text(formattedDate(qt.date))
                        .font(DS.Font.caption())
                        .foregroundStyle(DS.Color.textSecondary)
                }

                // 2행: 사용자 작성 내용 (크게, 3~4줄)
                if let summary = summaryText(qt), !summary.isEmpty {
                    Text(summary)
                        .font(.system(size: 17, weight: .regular, design: .default))
                        .foregroundStyle(DS.Color.textPrimary)
                        .lineLimit(4)
                        .lineSpacing(6)
                }

                // 3행: 뱃지 + 즐겨찾기
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

                    // 즐겨찾기 토글
                    Button {
                        Haptics.tap()
                        viewModel.send(.toggleFavorite(qt))
                    } label: {
                        Image(systemName: qt.isFavorite ? "star.fill" : "star")
                            .foregroundStyle(qt.isFavorite ? DS.Color.gold : DS.Color.textSecondary)
                            .font(.system(size: 20))
                    }
                }
            }
            .padding(DS.Spacing.xl)  // 더 넉넉한 패딩
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

                Image(systemName: "book.closed")
                    .font(.system(size: 60))
                    .foregroundStyle(DS.Color.gold)
            }

            VStack(spacing: DS.Spacing.s) {
                Text("아직 기록이 없어요")
                    .font(DS.Font.titleL(.semibold))
                    .foregroundStyle(DS.Color.textPrimary)

                Text("오늘의 말씀에서 시작해 보세요")
                    .font(DS.Font.bodyM())
                    .foregroundStyle(DS.Color.textSecondary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers
    func summaryText(_ qt: QuietTime) -> String? {
        if qt.template == "SOAP" {
            // SOAP: Observation → Application → Prayer 순서로 첫 번째 작성된 내용 반환
            if let observation = qt.soapObservation?.trimmingCharacters(in: .whitespacesAndNewlines),
               !observation.isEmpty {
                return observation
            }
            if let application = qt.soapApplication?.trimmingCharacters(in: .whitespacesAndNewlines),
               !application.isEmpty {
                return application
            }
            if let prayer = qt.soapPrayer?.trimmingCharacters(in: .whitespacesAndNewlines),
               !prayer.isEmpty {
                return prayer
            }
        } else {
            // ACTS: Adoration → Confession → Thanksgiving → Supplication 순서로 첫 번째 작성된 내용 반환
            if let adoration = qt.actsAdoration?.trimmingCharacters(in: .whitespacesAndNewlines),
               !adoration.isEmpty {
                return adoration
            }
            if let confession = qt.actsConfession?.trimmingCharacters(in: .whitespacesAndNewlines),
               !confession.isEmpty {
                return confession
            }
            if let thanksgiving = qt.actsThanksgiving?.trimmingCharacters(in: .whitespacesAndNewlines),
               !thanksgiving.isEmpty {
                return thanksgiving
            }
            if let supplication = qt.actsSupplication?.trimmingCharacters(in: .whitespacesAndNewlines),
               !supplication.isEmpty {
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
