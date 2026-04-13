//
//  QTListViewModel.swift
//  Presentation
//
//  Created by 이승주 on 10/12/25.
//

import Foundation
import Domain

/// QT 리스트 화면 ViewModel
@Observable
public final class QTListViewModel {
    // MARK: - State
    public private(set) var state: QTListState

    // MARK: - Dependencies
    private let fetchQTListUseCase: FetchQTListUseCase
    private let toggleFavoriteUseCase: ToggleFavoriteUseCase
    private let deleteQTUseCase: DeleteQTUseCase
    private let session: UserSession

    // MARK: - Debounce
    private var searchTask: Task<Void, Never>?

    // MARK: - Init
    private static let calendarExpandedKey = "isCalendarExpanded"

    public init(
        fetchQTListUseCase: FetchQTListUseCase,
        toggleFavoriteUseCase: ToggleFavoriteUseCase,
        deleteQTUseCase: DeleteQTUseCase,
        session: UserSession
    ) {
        let savedExpanded = UserDefaults.standard.object(forKey: Self.calendarExpandedKey) as? Bool ?? true
        self.state = QTListState(isCalendarExpanded: savedExpanded)
        self.fetchQTListUseCase = fetchQTListUseCase
        self.toggleFavoriteUseCase = toggleFavoriteUseCase
        self.deleteQTUseCase = deleteQTUseCase
        self.session = session
    }

    // MARK: - Calendar Helpers
    private static let dateKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private let calendar = Calendar.current

    // MARK: - Send Action
    public func send(_ action: QTListAction) {
        switch action {
        case .load:
            Task { await load() }

        case .loadMore:
            Task { await loadMore() }

        case .updateSearchText(let text, let isSearchMode):
            let previousText = state.searchText
            state.searchText = text

            // 텍스트가 실제로 변경되지 않았으면 아무것도 안 함
            guard previousText != text else { return }

            // 이전 검색 Task 취소
            searchTask?.cancel()

            // 검색 모드일 때는 검색어가 있을 때만 로드
            if isSearchMode {
                if !text.isEmpty {
                    // 검색어가 변경되면 즉시 기존 리스트 비우기 (깜빡임 방지)
                    state.qtList = []

                    // 200ms 후 검색 실행 (debounce)
                    searchTask = Task {
                        try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
                        guard !Task.isCancelled else { return }
                        await load()
                    }
                } else {
                    // 검색어가 비어지면 즉시 리스트 비우기
                    state.qtList = []
                }
                // 검색어가 비어있으면 아무것도 안 함 (빈 화면 유지)
            } else {
                // 일반 모드: 검색어가 비어있으면 즉시 로드
                if text.isEmpty {
                    Task { await load() }
                } else {
                    // 200ms 후 검색 실행 (debounce)
                    searchTask = Task {
                        try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
                        guard !Task.isCancelled else { return }
                        await load()
                    }
                }
            }

        case .selectFilter(let filter):
            state.selectedFilter = filter
            // 필터 변경 시 새로 로드
            Task { await load() }

        case .selectSort(let sort):
            state.selectedSort = sort

        case .toggleFavorite(let qt):
            Task { await toggleFavorite(qt) }

        case .confirmDelete(let qt):
            state.qtToDelete = qt
            state.showDeleteAlert = true

        case .deleteQT:
            Task { await deleteQT() }

        case .cancelDelete:
            state.qtToDelete = nil
            state.showDeleteAlert = false

        case .insertAtTop(let qt):
            // 중복 체크: 이미 있으면 추가하지 않음
            if !state.qtList.contains(where: { $0.id == qt.id }) {
                state.qtList.insert(qt, at: 0)
                state.lastLoadTime = Date()  // 갱신 시간 기록
                state.newlyAddedQTId = qt.id  // 스크롤을 위해 ID 저장
            }

        case .updateItem(let qt):
            if let index = state.qtList.firstIndex(where: { $0.id == qt.id }) {
                state.qtList[index] = qt
            }

        case .removeItem(let uuid):
            state.qtList.removeAll { $0.id == uuid }

        case .clearNewlyAddedId:
            state.newlyAddedQTId = nil

        // MARK: - Calendar Actions
        case .loadCalendar:
            Task { await loadCalendar() }

        case .changeMonth(let offset):
            if let newMonth = calendar.date(byAdding: .month, value: offset, to: state.displayedMonth) {
                state.displayedMonth = newMonth
                state.selectedDate = nil
                Task { await loadCalendar() }
            }

        case .selectDate(let date):
            state.selectedDate = date

        case .toggleCalendar:
            state.isCalendarExpanded.toggle()
            UserDefaults.standard.set(state.isCalendarExpanded, forKey: Self.calendarExpandedKey)
        }
    }

    // MARK: - Actions
    private func load() async {
        // 이미 로딩 중이면 리턴 (race condition 방지)
        guard !state.isLoading else {
            return
        }

        state.isLoading = true
        state.currentPage = 0

        do {
            // 검색어와 필터를 Query에 포함
            let searchText = state.searchText.isEmpty ? nil : state.searchText
            let isFavorite: Bool? = state.selectedFilter == .favorite ? true : nil

            let query = QTQuery(
                isFavorite: isFavorite,
                searchText: searchText,
                limit: 20,
                offset: 0
            )
            let list = try await fetchQTListUseCase.execute(query: query, session: session)

            await MainActor.run {
                state.qtList = list
                state.hasMoreData = list.count == 20
                state.isLoading = false
                state.lastLoadTime = Date()  // 로드 시간 기록
            }
        } catch {
            await MainActor.run {
                state.qtList = []
                state.hasMoreData = false
                state.isLoading = false
            }
        }
    }

    private func loadMore() async {
        // 이미 로딩 중이거나 더 이상 데이터가 없으면 리턴
        guard !state.isLoadingMore && !state.isLoading && state.hasMoreData else {
            return
        }

        state.isLoadingMore = true
        let nextPage = state.currentPage + 1

        do {
            // 검색어와 필터를 Query에 포함
            let searchText = state.searchText.isEmpty ? nil : state.searchText
            let isFavorite: Bool? = state.selectedFilter == .favorite ? true : nil

            let query = QTQuery(
                isFavorite: isFavorite,
                searchText: searchText,
                limit: 20,
                offset: nextPage * 20
            )
            let newList = try await fetchQTListUseCase.execute(query: query, session: session)

            await MainActor.run {
                state.qtList.append(contentsOf: newList)
                state.currentPage = nextPage
                state.hasMoreData = newList.count == 20
                state.isLoadingMore = false
            }
        } catch {
            await MainActor.run {
                state.isLoadingMore = false
            }
        }
    }

    private func toggleFavorite(_ qt: QuietTime) async {
        // Optimistic update: 로컬 state 먼저 업데이트
        if let index = state.qtList.firstIndex(where: { $0.id == qt.id }) {
            await MainActor.run {
                var updatedQT = state.qtList[index]
                updatedQT.isFavorite.toggle()
                state.qtList[index] = updatedQT
            }
        }

        // 백그라운드에서 서버 업데이트
        do {
            _ = try await toggleFavoriteUseCase.execute(id: qt.id, session: session)
        } catch {
            // 실패 시 롤백
            if let index = state.qtList.firstIndex(where: { $0.id == qt.id }) {
                await MainActor.run {
                    var revertedQT = state.qtList[index]
                    revertedQT.isFavorite.toggle()
                    state.qtList[index] = revertedQT
                }
            }
        }
    }

    private func deleteQT() async {
        guard let qt = state.qtToDelete else { return }

        do {
            try await deleteQTUseCase.execute(id: qt.id, session: session)

            await MainActor.run {
                NotificationCenter.default.post(
                    name: .qtDidChange,
                    object: QTChangeType.deleted(qt.id)
                )
                state.qtList.removeAll { $0.id == qt.id }
                state.qtToDelete = nil
                state.showDeleteAlert = false
            }
        } catch {
            await MainActor.run {
                state.showDeleteAlert = false
            }
        }
    }

    // MARK: - Calendar Logic

    private func loadCalendar() async {
        do {
            // 현재 표시 중인 월의 전체 QT 가져오기
            guard let monthInterval = calendar.dateInterval(of: .month, for: state.displayedMonth) else { return }

            let query = QTQuery(
                dateRange: DateRange(start: monthInterval.start, end: monthInterval.end),
                limit: 100,
                offset: 0
            )
            let monthQTs = try await fetchQTListUseCase.execute(query: query, session: session)

            // 날짜별 상태 계산
            var calendarMap: [String: QTDayStatus] = [:]
            for qt in monthQTs {
                let key = Self.dateKeyFormatter.string(from: qt.date)
                let existing = calendarMap[key] ?? .none
                if qt.status == .committed {
                    calendarMap[key] = .completed  // committed 우선
                } else if existing != .completed {
                    calendarMap[key] = .verseOnly
                }
            }

            // 이번 달 완료 횟수
            let completedCount = calendarMap.values.filter { $0 == .completed }.count

            // 연속 QT 일수 계산
            let streak = await calculateStreak()

            await MainActor.run {
                state.calendarData = calendarMap
                state.monthlyCount = completedCount
                state.currentStreak = streak
            }
        } catch {
            // 실패 시 빈 데이터
        }
    }

    private func calculateStreak() async -> Int {
        // 어제부터 역순으로 committed QT가 있는 연속 일수 계산
        // (오늘은 아직 진행 중이므로 제외, 오늘 QT가 있으면 별도로 +1)
        var streak = 0

        // 오늘 QT 여부 먼저 확인
        let todayStart = calendar.startOfDay(for: Date())
        let todayEnd = calendar.date(byAdding: .day, value: 1, to: todayStart) ?? todayStart

        let hasTodayQT: Bool
        do {
            let query = QTQuery(
                dateRange: DateRange(start: todayStart, end: todayEnd),
                limit: 1,
                offset: 0
            )
            let todayQTs = try await fetchQTListUseCase.execute(query: query, session: session)
            hasTodayQT = todayQTs.contains { $0.status == .committed }
        } catch {
            hasTodayQT = false
        }

        if hasTodayQT {
            streak = 1
        }

        // 어제부터 역순으로 연속 일수 계산
        var checkDate = calendar.date(byAdding: .day, value: -1, to: todayStart) ?? todayStart

        for _ in 0..<90 {
            let dayStart = calendar.startOfDay(for: checkDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart

            do {
                let query = QTQuery(
                    dateRange: DateRange(start: dayStart, end: dayEnd),
                    limit: 1,
                    offset: 0
                )
                let dayQTs = try await fetchQTListUseCase.execute(query: query, session: session)
                let hasCommitted = dayQTs.contains { $0.status == .committed }

                if hasCommitted {
                    streak += 1
                } else {
                    break
                }
            } catch {
                break
            }

            guard let prevDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prevDay
        }

        return streak
    }

    // MARK: - Filter Logic
    public var filteredAndSortedList: [QuietTime] {
        var filtered = state.qtList

        // 날짜 필터 (달력에서 선택)
        if let selectedDate = state.selectedDate {
            filtered = filtered.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
        }

        // 템플릿 필터는 로컬에서 처리 (서버에서는 검색/즐겨찾기만 처리)
        switch state.selectedFilter {
        case .all, .favorite:
            break
        case .soap:
            filtered = filtered.filter { $0.template == "SOAP" }
        case .free:
            filtered = filtered.filter { $0.template == "FREE" }
        }

        // 정렬 적용 (로컬)
        switch state.selectedSort {
        case .newest:
            filtered.sort { $0.date > $1.date }
        case .oldest:
            filtered.sort { $0.date < $1.date }
        }

        return filtered
    }
}
