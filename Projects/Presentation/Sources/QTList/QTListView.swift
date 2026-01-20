//
//  QTListView.swift
//  Presentation
//
//  Created by 이승주 on 10/12/25.
//

import SwiftUI
import Domain

// MARK: - Notification Names

extension Notification.Name {
    static let qtDidChange = Notification.Name("qtDidChange")
}

public struct QTListView: View {
    @State private var viewModel: QTListViewModel
    @Binding var userProfile: UserProfile?
    @State private var navigationPath = NavigationPath()
    @State private var scrollPosition: UUID?
    @SceneStorage("qt.list.scrollPosition") private var persistedScrollId: String?
    @FocusState private var isSearchFocused: Bool
    @State private var cancelSlotWidth: CGFloat = 0
    @State private var showCancelButton: Bool = false
    @State private var cancelButtonWorkItem: DispatchWorkItem?

    let detailViewModelFactory: (QuietTime) -> QTDetailViewModel
    let editorViewModelFactory: () -> QTEditorViewModel
    let profileEditViewModelFactory: (UserProfile?) -> ProfileEditViewModel
    let getUserProfileUseCase: GetUserProfileUseCase
    let onNavigateToMyPage: () -> Void

    public init(
        viewModel: QTListViewModel,
        userProfile: Binding<UserProfile?>,
        detailViewModelFactory: @escaping (QuietTime) -> QTDetailViewModel,
        editorViewModelFactory: @escaping () -> QTEditorViewModel,
        profileEditViewModelFactory: @escaping (UserProfile?) -> ProfileEditViewModel,
        getUserProfileUseCase: GetUserProfileUseCase,
        onNavigateToMyPage: @escaping () -> Void
    ) {
        _viewModel = State(wrappedValue: viewModel)
        _userProfile = userProfile
        self.detailViewModelFactory = detailViewModelFactory
        self.editorViewModelFactory = editorViewModelFactory
        self.profileEditViewModelFactory = profileEditViewModelFactory
        self.getUserProfileUseCase = getUserProfileUseCase
        self.onNavigateToMyPage = onNavigateToMyPage
    }

    public var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                CrossSunsetBackground()

                List {
                    // 검색바
                    searchBar()
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: DS.Spacing.m, leading: 0, bottom: 0, trailing: 0))

                    // 필터 바
                    filterBar()
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())

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
                        // ⚠️ CRITICAL: QuietTime.id는 반드시 안정적이어야 함
                        // - DB에서 fetch할 때마다 새 UUID()를 생성하면 스크롤 유지 불가능
                        // - 반드시 DB의 고정 ID를 QuietTime.id로 사용해야 함
                        // - 현재 구조상 QuietTime.id는 생성 시 고정된 UUID로 가정
                        ForEach(viewModel.filteredAndSortedList, id: \.id) { qt in
                            entryCell(qt)
                                .id(qt.id)  // scrollPosition 추적용 필수
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    navigationPath.append(qt)
                                }
                                .onAppear {
                                    // 화면에 보이는 셀 id를 지속적으로 저장
                                    scrollPosition = qt.id
                                    persistedScrollId = qt.id.uuidString

                                    // 페이징: 마지막에서 5번째 아이템이 보이면 다음 페이지 로드
                                    if let index = viewModel.filteredAndSortedList.firstIndex(where: { $0.id == qt.id }),
                                       index >= viewModel.filteredAndSortedList.count - 5 {
                                        viewModel.send(.loadMore)
                                    }
                                }
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: DS.Spacing.m/2, leading: DS.Spacing.l, bottom: DS.Spacing.m/2, trailing: DS.Spacing.l))
                        }

                        // 로딩 인디케이터
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
                .onChange(of: navigationPath.count) { oldCount, newCount in
                    // 뒤로 돌아왔을 때 (pop 감지)
                    if newCount < oldCount {
                        // SceneStorage에서 복원된 id 우선 사용
                        let targetId: UUID? = {
                            if let persisted = persistedScrollId, let uuid = UUID(uuidString: persisted) {
                                return uuid
                            }
                            return scrollPosition
                        }()

                        guard let finalId = targetId else { return }

                        // 2-step 강제 복원: nil로 흔들고 → 다시 설정
                        DispatchQueue.main.async {
                            scrollPosition = nil
                        }
                        DispatchQueue.main.async {
                            scrollPosition = finalId
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
            .navigationTitle("기록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ProfileHeaderView(profile: userProfile) {
                        Haptics.tap()
                        onNavigateToMyPage()
                    }
                    .id(userProfile?.nickname ?? "default")
                }
            }
            .onAppear {
                // SceneStorage에서 스크롤 위치 복원
                if let persisted = persistedScrollId, let uuid = UUID(uuidString: persisted) {
                    scrollPosition = uuid
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .qtDidChange)) { _ in
                // QT 작성/수정/삭제 시 리스트 갱신
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
        }
    }
}

// MARK: - Subviews
private extension QTListView {
    @ViewBuilder
    func searchBar() -> some View {
        let cancelWidth: CGFloat = 32      //
        let reservedGap: CGFloat = 8      //
        let reservedWidth = cancelWidth + reservedGap

        ZStack(alignment: .trailing) {

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
                .focused($isSearchFocused)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(DS.Color.canvas.opacity(0.9))
            )
            .padding(.trailing, cancelSlotWidth)
            .animation(.easeInOut(duration: 0.2), value: cancelSlotWidth)

            Button {
                Haptics.tap()
                viewModel.send(.updateSearchText(""))
                isSearchFocused = false
            } label: {
                Text("취소")
                    .font(DS.Font.bodyM(.medium))
                    .foregroundStyle(DS.Color.gold)
            }
            .frame(width: cancelWidth, alignment: .trailing)
            .opacity(showCancelButton ? 1 : 0)
            .allowsHitTesting(showCancelButton)
        }
        .padding(.horizontal, DS.Spacing.l)
        .onChange(of: isSearchFocused) { _, focused in
            cancelButtonWorkItem?.cancel()

            if focused {
                cancelSlotWidth = reservedWidth

                let workItem = DispatchWorkItem {
                    withAnimation(.easeIn(duration: 0.12)) {
                        showCancelButton = true
                    }
                }
                cancelButtonWorkItem = workItem
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)

            } else {
                withAnimation(.easeOut(duration: 0.1)) {
                    showCancelButton = false
                }
                cancelSlotWidth = 0
            }
        }
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
    func entryCell(_ qt: QuietTime) -> some View {
        SoftCard {
            VStack(alignment: .leading, spacing: DS.Spacing.l) {
                // 1행: 말씀 제목 (크고 두껍게) + 날짜
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

                // 2행: 사용자 작성 내용 (크게, 3~4줄)
                if let summary = summaryText(qt), !summary.isEmpty {
                    Text(summary)
                        .font(.system(size: 15, weight: .regular, design: .default))
                        .foregroundStyle(DS.Color.textPrimary)
                        .lineLimit(4)
                        .lineSpacing(5)
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
                            .padding(8)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
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
                    .font(DS.Font.titleM(.semibold))
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
