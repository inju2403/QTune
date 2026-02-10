//
//  QTListView.swift
//  Presentation
//
//  Created by 이승주 on 10/12/25.
//

import SwiftUI
import Domain

public struct QTListView: View {

    // MARK: - State
    @State private var viewModel: QTListViewModel
    @Binding var userProfile: UserProfile?
    @Binding var path: NavigationPath

    @State private var scrollPosition: UUID?
    @AppStorage("pendingNewQTId") private var pendingNewQTId: String?

    @FocusState private var isSearchFocused: Bool
    @Environment(\.fontScale) private var fontScale
    @State private var cancelSlotWidth: CGFloat = 0
    @State private var showCancelButton: Bool = false
    @State private var cancelButtonWorkItem: DispatchWorkItem?

    /// iOS 26+ 기록 탭에서는 검색바 숨김
    let hideSearchBar: Bool

    // MARK: - Dependencies
    let detailViewModelFactory: (QuietTime) -> QTDetailViewModel
    let editorViewModelFactory: () -> QTEditorViewModel
    let profileEditViewModelFactory: (UserProfile?) -> ProfileEditViewModel
    let getUserProfileUseCase: GetUserProfileUseCase
    let onNavigateToMyPage: () -> Void

    // MARK: - Init
    public init(
        viewModel: QTListViewModel,
        userProfile: Binding<UserProfile?>,
        path: Binding<NavigationPath>,
        detailViewModelFactory: @escaping (QuietTime) -> QTDetailViewModel,
        editorViewModelFactory: @escaping () -> QTEditorViewModel,
        profileEditViewModelFactory: @escaping (UserProfile?) -> ProfileEditViewModel,
        getUserProfileUseCase: GetUserProfileUseCase,
        onNavigateToMyPage: @escaping () -> Void,
        hideSearchBar: Bool = false
    ) {
        _viewModel = State(wrappedValue: viewModel)
        _userProfile = userProfile
        _path = path

        self.detailViewModelFactory = detailViewModelFactory
        self.editorViewModelFactory = editorViewModelFactory
        self.profileEditViewModelFactory = profileEditViewModelFactory
        self.getUserProfileUseCase = getUserProfileUseCase
        self.onNavigateToMyPage = onNavigateToMyPage
        self.hideSearchBar = hideSearchBar
    }

    // MARK: - Body
    public var body: some View {
        ZStack {
            CrossSunsetBackground()

            ScrollViewReader { scrollProxy in
                List {
                if !hideSearchBar {
                    searchBar()
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: DS.Spacing.m, leading: 0, bottom: 0, trailing: 0))
                }

                filterBar()
                    .id("filterBar") // 스크롤 타겟용 ID
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())

                if viewModel.state.isLoading {
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
                                path.append(QTRoute.detail(qt))
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
            .onAppear {
                // 1. 먼저 pendingNewQTId 체크 (NotificationCenter 못 받았을 경우)
                if let pendingId = pendingNewQTId, !pendingId.isEmpty {
                    // UserDefaults 클리어
                    UserDefaults.standard.removeObject(forKey: "pendingNewQTId")

                    // 강제로 로드 (새 QT 포함된 최신 데이터)
                    viewModel.send(.load)

                    // 로드 후 스크롤
                    Task { @MainActor in
                        // 로드 완료 대기
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초 (충분한 로드 시간)

                        // 맨 위로 스크롤
                        withAnimation {
                            scrollProxy.scrollTo("filterBar", anchor: .top)
                        }
                    }
                }
                // 2. newlyAddedQTId가 있는 경우 (NotificationCenter로 이미 추가됨)
                else if viewModel.state.newlyAddedQTId != nil {
                    // 무조건 최신 데이터 로드 (Notification 못 받았을 수 있음)
                    viewModel.send(.load)

                    // View 렌더링 후 스크롤 실행
                    Task { @MainActor in
                        // 로드 완료 대기
                        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3초 (로드 시간 충분히)

                        // 스크롤 실행
                        withAnimation {
                            // filterBar로 스크롤하면 필터/정렬 버튼까지 보임
                            scrollProxy.scrollTo("filterBar", anchor: .top)
                        }

                        // 첫 번째 항목으로 scrollPosition 설정
                        if let firstId = viewModel.filteredAndSortedList.first?.id {
                            scrollPosition = firstId
                        }

                        // 스크롤 후 플래그 클리어
                        viewModel.send(.clearNewlyAddedId)
                    }
                }
                // 3. 일반 진입
                else {
                    // 일반 진입: 데이터 로드 조건
                    let shouldLoad = viewModel.state.qtList.isEmpty && viewModel.state.lastLoadTime == nil

                    if shouldLoad {
                        viewModel.send(.load)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .qtDidChange)) { notification in
            guard let changeType = notification.object as? QTChangeType else {
                // 타입 정보 없으면 전체 로드 (하위 호환)
                viewModel.send(.load)
                return
            }

            switch changeType {
            case .created(let qt):
                // 새 QT 작성: 맨 위에 추가
                viewModel.send(.insertAtTop(qt))
                // newlyAddedQTId는 ViewModel에서 설정됨

                // pendingNewQTId 클리어 (혹시 남아있을 경우)
                if pendingNewQTId == qt.id.uuidString {
                    UserDefaults.standard.removeObject(forKey: "pendingNewQTId")
                }

                // 바로 스크롤 실행 (View가 이미 렌더링된 경우)
                Task { @MainActor in
                    // UI 업데이트 대기
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초

                    // 맨 위로 스크롤
                    withAnimation {
                        scrollProxy.scrollTo("filterBar", anchor: .top)
                    }
                }

            case .updated(let qt):
                // QT 수정: 해당 항목만 교체 (스크롤 위치 유지!)
                viewModel.send(.updateItem(qt))

            case .deleted(let uuid):
                // 삭제 시 스크롤 위치 보정 (삭제 전에 인접 항목으로 이동)
                if let index = viewModel.filteredAndSortedList.firstIndex(where: { $0.id == uuid }) {
                    if index > 0 {
                        // 위에 항목이 있으면 위로
                        scrollPosition = viewModel.filteredAndSortedList[index - 1].id
                    } else if viewModel.filteredAndSortedList.count > 1 {
                        // 첫 번째 항목이면 다음 항목으로
                        scrollPosition = viewModel.filteredAndSortedList[1].id
                    } else {
                        // 마지막 남은 항목이면 nil
                        scrollPosition = nil
                    }
                }
                // 리스트에서 제거
                viewModel.send(.removeItem(uuid))
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
        .navigationDestination(for: QTRoute.self) { route in
            switch route {
            case .detail(let qt):
                QTDetailView(
                    viewModel: detailViewModelFactory(qt),
                    editorViewModelFactory: editorViewModelFactory
                )
            case .result, .editor:
                EmptyView()
            }
        }
            } // End of ScrollViewReader
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
    }
}

// MARK: - Subviews
private extension QTListView {

    @ViewBuilder
    func searchBar() -> some View {
        let cancelWidth: CGFloat = 32
        let reservedGap: CGFloat = 8
        let reservedWidth = cancelWidth + reservedGap

        ZStack(alignment: .trailing) {
            HStack(spacing: DS.Spacing.m) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(DS.Color.gold)
                    .font(DS.Font.bodyL())

                TextField("말씀, 태그, 내용으로 검색", text: Binding(
                    get: { viewModel.state.searchText },
                    set: { viewModel.send(.updateSearchText($0, isSearchMode: false)) }
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
                viewModel.send(.updateSearchText("", isSearchMode: false))
                isSearchFocused = false
            } label: {
                Text("취소")
                    .dsBodyM(.medium)
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
                    .dsBodyM(.medium)
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
                    .dsBodyM(.medium)
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
                HStack(alignment: .top) {
                    Text(qt.verse.localizedId)
                        .font(.system(size: 21 * fontScale.multiplier, weight: .bold, design: .serif))
                        .foregroundStyle(DS.Color.deepCocoa)
                        .lineLimit(2)

                    Spacer()

                    Text(formattedDate(qt.date))
                        .dsCaption()
                        .foregroundStyle(DS.Color.textSecondary)
                }

                if let summary = summaryText(qt), !summary.isEmpty {
                    Text(summary)
                        .dsBodyM()
                        .foregroundStyle(DS.Color.textPrimary)
                        .lineLimit(4)
                }

                HStack(spacing: DS.Spacing.s) {
                    Text(qt.template)
                        .dsCaption(.medium)
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
                            .font(.system(size: 20 * fontScale.multiplier))
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

                Image(systemName: "book.closed")
                    .font(.system(size: 60 * fontScale.multiplier))
                    .foregroundStyle(DS.Color.gold)
            }

            VStack(spacing: DS.Spacing.s) {
                Text("아직 기록이 없어요")
                    .dsTitleM(.semibold)
                    .foregroundStyle(DS.Color.textPrimary)

                Text("오늘의 말씀에서 시작해 보세요")
                    .dsBodyM()
                    .foregroundStyle(DS.Color.textSecondary)
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
