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
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(Color(white: 0.8))
                .frame(width: 36, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 28)

            // Main question
            VStack(spacing: 8) {
                Text("오늘 어떤 방식으로")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(DS.Color.deepCocoa)
                Text("말씀을 묵상하고 싶으신가요?")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(DS.Color.deepCocoa)
            }
            .multilineTextAlignment(.center)
            .padding(.bottom, 28)

            // Template cards
            VStack(spacing: 14) {
                TemplateCard(
                    icon: "book.closed.fill",
                    title: "SOAP",
                    subtitle: "말씀의 본질에 집중",
                    description: "말씀을 차분히 이해하고, 오늘의 삶에 연결하는 묵상. 생각을 정리하며 묵상하고 싶을 때 추천해요.",
                    buttonTitle: "SOAP 묵상하기"
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
                    buttonTitle: "ACTS 묵상하기"
                ) {
                    Haptics.tap()
                    onSelect(.acts)
                    dismiss()
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        VStack(alignment: .leading, spacing: 18) {
            // Icon + Title + Subtitle
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundStyle(DS.Color.gold)
                    .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(DS.Color.deepCocoa)
                    Text(subtitle)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }

            // Description
            Text(description)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(DS.Color.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 4)
                .padding(.bottom, 6)

            // Button
            Button(action: action) {
                Text(buttonTitle)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(DS.Color.gold)
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(DS.Color.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(DS.Color.gold.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
