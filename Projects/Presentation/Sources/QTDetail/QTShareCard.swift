//
//  QTShareCard.swift
//  Presentation
//
//  Created by 이승주 on 1/28/26.
//

import SwiftUI
import Domain

/// 실제 공유될 카드 내용 (말씀 + 해설 + Prayer/Thanksgiving 고정)
public struct QTShareCard: View {
    let qt: QuietTime

    public init(qt: QuietTime) {
        self.qt = qt
    }

    public var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()

                // 날짜 (베이지 배경 위)
                Text(formattedDate(qt.date))
                    .font(.system(size: 40, weight: .regular))
                    .foregroundStyle(Color(red: 0.42, green: 0.36, blue: 0.34))
                    .padding(.bottom, 60)

                // 날짜 아래 구분선
                Rectangle()
                    .fill(Color(red: 0.42, green: 0.36, blue: 0.34).opacity(0.3))
                    .frame(width: 100, height: 1)
                    .padding(.bottom, 60)

                // 흰색 카드
                VStack(alignment: .leading, spacing: 0) {
                    let verse = qt.verse

                    // 구절 참조 (왼쪽 정렬)
                    Text(formatVerseRef(verse))
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.9))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 44)

                    // 말씀 본문 (왼쪽 정렬)
                    Text(getVerseText(verse))
                        .font(.system(size: 38, weight: .regular))
                        .foregroundStyle(Color.black.opacity(0.85))
                        .lineSpacing(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 70)

                    // 해설
                    if let korean = qt.korean, !korean.isEmpty {
                        Text("해설")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(Color.black.opacity(0.65))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 14)

                        Text(korean)
                            .font(.system(size: 34, weight: .light))
                            .foregroundStyle(Color.black.opacity(0.8))
                            .lineSpacing(18)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 70)
                    }

                    // SOAP → Prayer, ACTS → Thanksgiving
                    if qt.template == "SOAP" {
                        if let prayer = qt.soapPrayer, !prayer.isEmpty {
                            Text("기도")
                                .font(.system(size: 30, weight: .semibold))
                                .foregroundStyle(Color.black.opacity(0.65))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.bottom, 14)

                            Text(prayer)
                                .font(.system(size: 34, weight: .light))
                                .foregroundStyle(Color.black.opacity(0.85))
                                .lineSpacing(18)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    } else {
                        if let thanksgiving = qt.actsThanksgiving, !thanksgiving.isEmpty {
                            Text("감사")
                                .font(.system(size: 30, weight: .semibold))
                                .foregroundStyle(Color.black.opacity(0.65))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.bottom, 14)

                            Text(thanksgiving)
                                .font(.system(size: 34, weight: .light))
                                .foregroundStyle(Color.black.opacity(0.85))
                                .lineSpacing(18)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(.horizontal, 50)
                .padding(.vertical, 50)
                .background(.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 3)
                .padding(.horizontal, 50)

                Spacer()

                // QTune 로고
                Text("QTune")
                    .font(.system(size: 36, weight: .regular))
                    .foregroundStyle(Color.black.opacity(0.3))

                // QTune 아래 구분선
                Rectangle()
                    .fill(Color.black.opacity(0.15))
                    .frame(width: 280, height: 1)
                    .padding(.bottom, 100)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(Color(red: 0.976, green: 0.953, blue: 0.933)) // #f9f3ee 베이지색 배경
        }
        .frame(width: 1080, height: 1920) // 9:16 비율 (Instagram Story 크기)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }

    private func formatVerseRef(_ verse: Verse) -> String {
        // 역본에 따라 책명 표시
        return "\(verse.localizedBookName) \(verse.chapter):\(verse.verse)"
    }

    private func getVerseText(_ verse: Verse) -> String {
        // 말씀 본문만 반환
        return verse.text
    }
}
