//
//  QTCalendarView.swift
//  Presentation
//
//  Created by 이승주 on 4/12/26.
//

import SwiftUI

/// QT 달력 뷰 — 기록 탭 상단에 표시되는 월간 달력
struct QTCalendarView: View {
    let displayedMonth: Date
    let selectedDate: Date?
    let calendarData: [String: QTDayStatus]
    let currentStreak: Int
    let monthlyCount: Int
    let isExpanded: Bool
    let onChangeMonth: (Int) -> Void
    let onSelectDate: (Date?) -> Void
    let onToggle: () -> Void

    @Environment(\.fontScale) private var fontScale

    private let calendar = Calendar.current
    private let weekdaySymbols = ["일", "월", "화", "수", "목", "금", "토"]

    private static let dateKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - 헤더 (월 + 네비게이션 + 접기 버튼)
            calendarHeader()

            if isExpanded {
                // MARK: - 요일 헤더
                weekdayHeader()
                    .padding(.top, 8)

                // MARK: - 날짜 그리드
                dateGrid()
                    .padding(.top, 4)
            }

            // MARK: - 스트릭 정보
            streakBar()
                .padding(.top, isExpanded ? 12 : 4)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(DS.Color.canvas.opacity(0.9))
        .cornerRadius(DS.Radius.m)
        .padding(.horizontal, DS.Spacing.l)
    }
}

// MARK: - Subviews
private extension QTCalendarView {

    @ViewBuilder
    func calendarHeader() -> some View {
        HStack(spacing: 0) {
            // 월 네비게이션: < 2026년 4월 >
            HStack(spacing: 4) {
                Button {
                    Haptics.tap()
                    onChangeMonth(-1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DS.Color.mocha)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.borderless)

                Text(monthYearString)
                    .font(.system(size: 17 * fontScale.multiplier, weight: .bold, design: .rounded))
                    .foregroundStyle(DS.Color.deepCocoa)

                if canGoForward {
                    Button {
                        Haptics.tap()
                        onChangeMonth(1)
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(DS.Color.mocha)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.borderless)
                } else {
                    Color.clear.frame(width: 32, height: 32)
                }
            }

            Spacer()

            // 접기/펼치기 토글 버튼
            Button {
                Haptics.tap()
                onToggle()
            } label: {
                Image(systemName: isExpanded ? "chevron.up.circle" : "chevron.down.circle")
                    .font(.system(size: 20))
                    .foregroundStyle(DS.Color.mocha)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.borderless)
        }
    }

    @ViewBuilder
    func weekdayHeader() -> some View {
        HStack(spacing: 0) {
            ForEach(weekdaySymbols, id: \.self) { day in
                Text(day)
                    .font(.system(size: 12 * fontScale.multiplier, weight: .medium))
                    .foregroundStyle(
                        day == "일" ? DS.Color.danger.opacity(0.7) :
                        day == "토" ? DS.Color.gold.opacity(0.8) :
                        DS.Color.textSecondary
                    )
                    .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    func dateGrid() -> some View {
        let days = daysInMonth()
        let rows = days.chunked(into: 7)

        VStack(spacing: 6) {
            ForEach(0..<rows.count, id: \.self) { rowIndex in
                HStack(spacing: 0) {
                    ForEach(0..<rows[rowIndex].count, id: \.self) { colIndex in
                        let day = rows[rowIndex][colIndex]
                        dayCell(day)
                            .frame(maxWidth: .infinity)
                    }
                    // 마지막 줄 패딩
                    if rows[rowIndex].count < 7 {
                        ForEach(0..<(7 - rows[rowIndex].count), id: \.self) { _ in
                            Color.clear.frame(maxWidth: .infinity, minHeight: 38)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    func dayCell(_ day: DayItem) -> some View {
        if let date = day.date {
            let dateKey = Self.dateKeyFormatter.string(from: date)
            let status = calendarData[dateKey] ?? .none
            let isToday = calendar.isDateInToday(date)
            let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
            let isFuture = date > Date()

            Button {
                Haptics.tap()
                if isSelected {
                    onSelectDate(nil)  // 선택 해제
                } else {
                    onSelectDate(date)
                }
            } label: {
                ZStack {
                    // 선택 표시 (상태 점 때문에 살짝 위로 올려서 숫자 중앙 정렬)
                    if isSelected {
                        Circle()
                            .fill(DS.Color.gold.opacity(0.2))
                            .frame(width: 36, height: 36)
                            .offset(y: -3)
                    }

                    // 오늘 표시
                    if isToday && !isSelected {
                        Circle()
                            .stroke(DS.Color.gold, lineWidth: 1.5)
                            .frame(width: 36, height: 36)
                            .offset(y: -3)
                    }

                    VStack(spacing: 2) {
                        Text("\(day.number)")
                            .font(.system(size: 14 * fontScale.multiplier, weight: isToday ? .bold : .regular))
                            .foregroundStyle(
                                isFuture ? DS.Color.textSecondary.opacity(0.4) :
                                isSelected ? DS.Color.deepCocoa :
                                DS.Color.textPrimary
                            )

                        // 상태 점
                        statusDot(status, isFuture: isFuture)
                    }
                }
                .frame(minHeight: 38)
            }
            .buttonStyle(.borderless)
            .disabled(isFuture)
        } else {
            // 빈 칸 (이전/다음 달)
            Color.clear.frame(minHeight: 38)
        }
    }

    @ViewBuilder
    func statusDot(_ status: QTDayStatus, isFuture: Bool) -> some View {
        switch status {
        case .completed:
            Circle()
                .fill(DS.Color.gold)
                .frame(width: 6, height: 6)
        case .verseOnly:
            Circle()
                .stroke(DS.Color.gold, lineWidth: 1.2)
                .frame(width: 6, height: 6)
        case .none:
            Circle()
                .fill(Color.clear)
                .frame(width: 6, height: 6)
        }
    }

    @ViewBuilder
    func streakBar() -> some View {
        HStack(spacing: 16) {
            // 연속 일수
            HStack(spacing: 5) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(currentStreak > 0 ? DS.Color.gold : DS.Color.textSecondary)

                Text("연속 \(currentStreak)일")
                    .font(.system(size: 13 * fontScale.multiplier, weight: .semibold, design: .rounded))
                    .foregroundStyle(currentStreak > 0 ? DS.Color.deepCocoa : DS.Color.textSecondary)
            }

            // 구분선
            Rectangle()
                .fill(DS.Color.divider)
                .frame(width: 1, height: 14)

            // 이번 달 완료
            HStack(spacing: 5) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(monthlyCount > 0 ? DS.Color.olive : DS.Color.textSecondary)

                Text("이번 달 \(monthlyCount)회")
                    .font(.system(size: 13 * fontScale.multiplier, weight: .semibold, design: .rounded))
                    .foregroundStyle(DS.Color.deepCocoa)
            }

            Spacer()

            // 선택 날짜 필터 해제
            if selectedDate != nil {
                Button {
                    Haptics.tap()
                    onSelectDate(nil)
                } label: {
                    Text("전체 보기")
                        .font(.system(size: 12 * fontScale.multiplier, weight: .medium))
                        .foregroundStyle(DS.Color.gold)
                }
                .buttonStyle(.borderless)
            }
        }
    }
}

// MARK: - Data Models & Helpers
private extension QTCalendarView {

    struct DayItem {
        let number: Int
        let date: Date?
    }

    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: displayedMonth)
    }

    var canGoForward: Bool {
        let now = Date()
        let currentMonth = calendar.dateInterval(of: .month, for: now)
        let displayedMonthInterval = calendar.dateInterval(of: .month, for: displayedMonth)
        return displayedMonthInterval?.start ?? Date() < currentMonth?.start ?? Date()
    }

    func daysInMonth() -> [DayItem] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let range = calendar.range(of: .day, in: .month, for: displayedMonth) else {
            return []
        }

        let firstDay = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstDay) // 1=일, 2=월, ...

        var days: [DayItem] = []

        // 빈 칸 (이전 달)
        let emptyDays = firstWeekday - 1  // 일요일 시작
        for _ in 0..<emptyDays {
            days.append(DayItem(number: 0, date: nil))
        }

        // 해당 월의 날짜
        for day in range {
            if let date = calendar.date(bySetting: .day, value: day, of: firstDay) {
                days.append(DayItem(number: day, date: date))
            }
        }

        return days
    }
}

// MARK: - Array Extension
private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
