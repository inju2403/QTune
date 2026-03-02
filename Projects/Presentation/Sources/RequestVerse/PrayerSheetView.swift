//
//  PrayerSheetView.swift
//  Presentation
//
//  Created by 이승주 on 3/2/26.
//

import SwiftUI
import Domain

/// 추천 기도문 바텀시트
/// AI가 추천한 기도문을 아름답게 표시하는 동적 높이 바텀시트
struct PrayerSheetView: View {
    let prayer: String
    @Binding var sheetHeight: CGFloat

    @Environment(\.fontScale) private var fontScale

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // 상단 아이콘과 타이틀
                VStack(spacing: 16) {
                    // 아이콘
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [DS.Color.gold.opacity(0.2), DS.Color.mocha.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60 * fontScale.multiplier, height: 60 * fontScale.multiplier)

                        Image(systemName: "hands.sparkles")
                            .font(.system(size: 26 * fontScale.multiplier, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [DS.Color.mocha, DS.Color.gold],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    // 타이틀
                    Text("추천 기도문")
                        .font(.system(size: 22 * fontScale.multiplier, weight: .bold, design: .rounded))
                        .foregroundStyle(DS.Color.mocha)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, DS.Spacing.xxl)
                .padding(.bottom, DS.Spacing.l)

                // 구분선
                Rectangle()
                    .fill(DS.Color.gold.opacity(0.2))
                    .frame(height: 1)
                    .padding(.horizontal, DS.Spacing.xl)

                // 기도문 내용
                ScrollView {
                    VStack(alignment: .leading, spacing: DS.Spacing.l) {
                        DSText.bodyL(prayer)
                            .foregroundStyle(DS.Color.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)
                    }
                    .padding(.horizontal, DS.Spacing.xl)
                    .padding(.top, DS.Spacing.l)
                    .padding(.bottom, DS.Spacing.xl)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
            .onAppear {
                // 실제 컨텐츠 높이 측정 후 시트 높이 설정
                DispatchQueue.main.async {
                    let contentWidth = geometry.size.width - (DS.Spacing.xl * 2)
                    let estimatedHeight = calculateTextHeight(
                        text: prayer,
                        width: contentWidth,
                        font: .systemFont(ofSize: 17 * fontScale.multiplier)
                    )
                    // icon(60) + spacing(16) + title(22) + top padding(32) + bottom padding(16) + divider(1) + content padding(16) + content + bottom padding(24) + extra(60)
                    let iconSize = 60 * fontScale.multiplier
                    let titleSize = 22 * fontScale.multiplier
                    let totalHeight = iconSize + 16 + titleSize + 32 + 16 + 1 + 16 + estimatedHeight + 24 + 60
                    sheetHeight = min(max(totalHeight, 280), UIScreen.main.bounds.height * 0.7)
                }
            }
        }
    }

    private func calculateTextHeight(text: String, width: CGFloat, font: UIFont) -> CGFloat {
        let textHeight = text.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        ).height

        return textHeight + (6 * 3) // dsBodyL의 기본 행간 6pt 고려
    }
}
