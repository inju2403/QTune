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
            VStack(spacing: 0) {
                // 검색바
                searchBar()

                // 필터 바
                filterBar()

                // 리스트
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if viewModel.filteredAndSortedList.isEmpty {
                    emptyStateView()
                } else {
                    entryList()
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
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("말씀, 태그, 내용으로 검색", text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .autocapitalization(.none)
                .disableAutocorrection(true)

            if !viewModel.searchText.isEmpty {
                Button(action: {
                    viewModel.searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    @ViewBuilder
    func filterBar() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // 필터
                Menu {
                    ForEach(QTListViewModel.FilterType.allCases, id: \.self) { filter in
                        Button(action: {
                            viewModel.selectedFilter = filter
                        }) {
                            HStack {
                                Text(filter.displayName)
                                if viewModel.selectedFilter == filter {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(viewModel.selectedFilter.displayName)
                        Image(systemName: "chevron.down")
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // 정렬
                Menu {
                    ForEach(QTListViewModel.SortType.allCases, id: \.self) { sort in
                        Button(action: {
                            viewModel.selectedSort = sort
                        }) {
                            HStack {
                                Text(sort.displayName)
                                if viewModel.selectedSort == sort {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(viewModel.selectedSort.displayName)
                        Image(systemName: "chevron.down")
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    func entryList() -> some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredAndSortedList) { qt in
                    NavigationLink(value: qt) {
                        entryCell(qt)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
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
        VStack(alignment: .leading, spacing: 8) {
            // 1행: verseRef + 날짜
            HStack {
                Text(qt.verse.id)
                    .font(.headline)
                    .foregroundColor(.blue)

                Spacer()

                Text(formattedDate(qt.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // 2행: 요약 텍스트
            if let summary = summaryText(qt), !summary.isEmpty {
                Text(summary)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }

            // 템플릿 뱃지 + 즐겨찾기
            HStack {
                Text(qt.template)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(qt.template == "SOAP" ? Color.blue.opacity(0.1) : Color.purple.opacity(0.1))
                    .foregroundColor(qt.template == "SOAP" ? .blue : .purple)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                Spacer()

                // 즐겨찾기 토글
                Button(action: {
                    Task {
                        await viewModel.toggleFavorite(qt)
                    }
                }) {
                    Image(systemName: qt.isFavorite ? "star.fill" : "star")
                        .foregroundColor(qt.isFavorite ? .yellow : .secondary)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    @ViewBuilder
    func emptyStateView() -> some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("아직 기록이 없어요")
                .font(.title3)
                .fontWeight(.semibold)

            Text("오늘의 말씀에서 시작해 보세요")
                .font(.body)
                .foregroundColor(.secondary)

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
