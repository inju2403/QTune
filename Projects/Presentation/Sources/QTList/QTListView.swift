//
//  QTListView.swift
//  Presentation
//
//  Created by 이승주 on 10/12/25.
//

import SwiftUI
import Domain

public struct QTListView: View {
    @StateObject private var viewModel: QTListViewModel
    let detailViewModelFactory: (QuietTime) -> QTDetailViewModel
    let editorViewModelFactory: () -> QTEditorViewModel

    public init(
        viewModel: QTListViewModel,
        detailViewModelFactory: @escaping (QuietTime) -> QTDetailViewModel,
        editorViewModelFactory: @escaping () -> QTEditorViewModel
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.detailViewModelFactory = detailViewModelFactory
        self.editorViewModelFactory = editorViewModelFactory
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                    .ignoresSafeArea()

                VStack(spacing: DS.Spacing.m) {
                    // 검색바
                    searchBar()

                    // 필터 바
                    filterBar()

                    // 리스트
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                            .tint(DS.Color.gold)
                            .controlSize(.large)
                        Spacer()
                    } else if viewModel.filteredAndSortedList.isEmpty {
                        emptyStateView()
                    } else {
                        entryList()
                    }
                }
            }
            .navigationTitle("기록")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.load()
            }
            .alert("기록 삭제", isPresented: $viewModel.showDeleteAlert) {
                Button("취소", role: .cancel) {
                    viewModel.cancelDelete()
                }
                Button("삭제", role: .destructive) {
                    Task {
                        await viewModel.deleteQT()
                    }
                }
            } message: {
                Text("이 기록을 삭제할까요? 이 작업은 되돌릴 수 없습니다.")
            }
        }
    }
}

// MARK: - Subviews
private extension QTListView {
    @ViewBuilder
    func searchBar() -> some View {
        SoftCard {
            HStack(spacing: DS.Spacing.m) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(DS.Color.gold)
                    .font(DS.Font.bodyL())

                TextField("말씀, 태그, 내용으로 검색", text: $viewModel.searchText)
                    .font(DS.Font.bodyM())
                    .foregroundStyle(DS.Color.textPrimary)
                    .textFieldStyle(.plain)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                if !viewModel.searchText.isEmpty {
                    Button {
                        Haptics.tap()
                        withAnimation(Motion.appear) {
                            viewModel.searchText = ""
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(DS.Color.textSecondary)
                            .font(DS.Font.bodyL())
                    }
                }
            }
        }
        .padding(.horizontal, DS.Spacing.l)
        .padding(.top, DS.Spacing.s)
    }

    @ViewBuilder
    func filterBar() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Spacing.m) {
                // 필터
                Menu {
                    ForEach(QTListViewModel.FilterType.allCases, id: \.self) { filter in
                        Button {
                            Haptics.tap()
                            withAnimation(Motion.appear) {
                                viewModel.selectedFilter = filter
                            }
                        } label: {
                            HStack {
                                Text(filter.displayName)
                                if viewModel.selectedFilter == filter {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: DS.Spacing.xs) {
                        Text(viewModel.selectedFilter.displayName)
                        Image(systemName: "chevron.down")
                            .font(DS.Font.caption())
                    }
                    .font(DS.Font.bodyM(.medium))
                    .foregroundStyle(DS.Color.textPrimary)
                    .padding(.horizontal, DS.Spacing.m)
                    .padding(.vertical, DS.Spacing.s)
                    .background(DS.Color.canvas)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(DS.Color.divider, lineWidth: 1))
                }

                // 정렬
                Menu {
                    ForEach(QTListViewModel.SortType.allCases, id: \.self) { sort in
                        Button {
                            Haptics.tap()
                            withAnimation(Motion.appear) {
                                viewModel.selectedSort = sort
                            }
                        } label: {
                            HStack {
                                Text(sort.displayName)
                                if viewModel.selectedSort == sort {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: DS.Spacing.xs) {
                        Text(viewModel.selectedSort.displayName)
                        Image(systemName: "chevron.down")
                            .font(DS.Font.caption())
                    }
                    .font(DS.Font.bodyM(.medium))
                    .foregroundStyle(DS.Color.textPrimary)
                    .padding(.horizontal, DS.Spacing.m)
                    .padding(.vertical, DS.Spacing.s)
                    .background(DS.Color.canvas)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(DS.Color.divider, lineWidth: 1))
                }
            }
            .padding(.horizontal, DS.Spacing.l)
        }
        .padding(.vertical, DS.Spacing.s)
    }

    @ViewBuilder
    func entryList() -> some View {
        ScrollView {
            LazyVStack(spacing: DS.Spacing.m) {
                ForEach(viewModel.filteredAndSortedList) { qt in
                    NavigationLink(value: qt) {
                        entryCell(qt)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(DS.Spacing.l)
        }
        .navigationDestination(for: QuietTime.self) { qt in
            QTDetailView(
                viewModel: detailViewModelFactory(qt),
                editorViewModelFactory: editorViewModelFactory
            )
        }
    }

    @ViewBuilder
    func entryCell(_ qt: QuietTime) -> some View {
        SoftCard {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                // 1행: verseRef + 날짜
                HStack {
                    Image(systemName: "book.closed.fill")
                        .foregroundStyle(DS.Color.gold)
                        .font(DS.Font.bodyM())

                    Text(qt.verse.id)
                        .font(DS.Font.bodyL(.semibold))
                        .foregroundStyle(DS.Color.deepCocoa)

                    Spacer()

                    Text(formattedDate(qt.date))
                        .font(DS.Font.caption())
                        .foregroundStyle(DS.Color.textSecondary)
                }

                // 2행: 요약 텍스트
                if let summary = summaryText(qt), !summary.isEmpty {
                    Text(summary)
                        .font(DS.Font.bodyM())
                        .foregroundStyle(DS.Color.textPrimary)
                        .lineLimit(2)
                        .lineSpacing(2)
                }

                // 템플릿 뱃지 + 즐겨찾기
                HStack(spacing: DS.Spacing.s) {
                    Text(qt.template)
                        .font(DS.Font.caption(.medium))
                        .foregroundStyle(qt.template == "SOAP" ? DS.Color.olive : DS.Color.gold)
                        .padding(.horizontal, DS.Spacing.s)
                        .padding(.vertical, DS.Spacing.xs)
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
                        Task {
                            await viewModel.toggleFavorite(qt)
                        }
                    } label: {
                        Image(systemName: qt.isFavorite ? "star.fill" : "star")
                            .foregroundStyle(qt.isFavorite ? DS.Color.gold : DS.Color.textSecondary)
                            .font(DS.Font.bodyL())
                    }
                    .animation(Motion.press, value: qt.isFavorite)
                }
            }
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
            return qt.soapObservation?.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            return qt.actsAdoration?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
}
