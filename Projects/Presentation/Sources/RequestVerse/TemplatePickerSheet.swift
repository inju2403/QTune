//
//  TemplatePickerSheet.swift
//  Presentation
//
//  Created by 이승주 on 10/19/25.
//

import SwiftUI

/// 템플릿 선택 바텀시트 (SOAP / ACTS)
public struct TemplatePickerSheet: View {
    let onSelect: (TemplateKind) -> Void
    @Environment(\.dismiss) private var dismiss

    public init(onSelect: @escaping (TemplateKind) -> Void) {
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(spacing: 20) {
            // Handle
            Capsule()
                .fill(DS.Color.textSecondary.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 20)
                .padding(.bottom, 8)

            // Header
            VStack(spacing: 4) {
                Text("두 가지 묵상 방식")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(DS.Color.deepCocoa)
                Text("SOAP · ACTS 중 선택하세요")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(DS.Color.textSecondary)
            }
            .padding(.bottom, 8)

            // Main question
            VStack(spacing: 8) {
                Text("오늘 어떤 방식으로")
                    .font(DS.Font.titleM(.semibold))
                    .foregroundStyle(DS.Color.deepCocoa)
                Text("말씀을 묵상하고 싶으신가요?")
                    .font(DS.Font.titleM(.semibold))
                    .foregroundStyle(DS.Color.deepCocoa)
            }
            .multilineTextAlignment(.center)

            // Info message
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(DS.Color.gold)
                Text("이번 말씀 추천에서 선택할 수 있습니다.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(DS.Color.textSecondary)
            }
            .padding(.bottom, 8)

            // Template cards
            VStack(spacing: 16) {
                TemplateCard(
                    icon: "book.closed.fill",
                    title: "SOAP",
                    subtitle: "말씀의 본질에 집중",
                    description: "말씀을 차분히 이해하고, 오늘의 삶에 연결하는 묵상. 생각을 정리하며 묵상하고 싶을 때 추천해요.",
                    buttonTitle: "SOAP방식 '오늘 성경읽기' 선택하기"
                ) {
                    Haptics.tap()
                    onSelect(.soap)
                    dismiss()
                }

                TemplateCard(
                    icon: "hands.and.sparkles.fill",
                    title: "ACTS",
                    subtitle: "기도로 대화하는 묵상",
                    description: "마음을 돌아보며 기도로 이어가는 묵상. 마음을 풀어놓고 묵상하고 싶을 때 추천해요.",
                    buttonTitle: "ACTS방식 '기도하며 성경읽기' 선택하기"
                ) {
                    Haptics.tap()
                    onSelect(.acts)
                    dismiss()
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .padding(.bottom, 12)
        .background(DS.Color.canvas)
    }
}

// MARK: - Template Card

private struct TemplateCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let description: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon + Title + Subtitle
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(DS.Color.gold)
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(DS.Color.deepCocoa)
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }

            // Description
            Text(description)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(DS.Color.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            // Button
            Button(action: action) {
                HStack(spacing: 6) {
                    Text(buttonTitle)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(DS.Color.gold)
                )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.m)
                .fill(DS.Color.background)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.m)
                        .stroke(DS.Color.gold.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
