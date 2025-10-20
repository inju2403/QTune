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
        VStack(spacing: 16) {
            // Handle
            Capsule()
                .fill(DS.Color.textSecondary.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 20)
                .padding(.bottom, 12)

            // Title
            Text("묵상 템플릿을 선택하세요")
                .font(DS.Font.titleM(.semibold))
                .foregroundStyle(DS.Color.deepCocoa)
                .padding(.top, 8)

            // Template cards
            HStack(spacing: 12) {
                TemplateCard(
                    title: "SOAP",
                    items: ["Observation", "Application", "Prayer"]
                ) {
                    Haptics.tap()
                    onSelect(.soap)
                    dismiss()
                }

                TemplateCard(
                    title: "ACTS",
                    items: ["Adoration", "Confession", "Thanksgiving", "Supplication"]
                ) {
                    Haptics.tap()
                    onSelect(.acts)
                    dismiss()
                }
            }
            .padding(.horizontal, 20)

            // Description
            Text("선택 후 단계별로 차분히 작성합니다.")
                .font(DS.Font.caption())
                .foregroundStyle(DS.Color.textSecondary)
                .padding(.bottom, 12)
        }
        .padding(.bottom, 12)
        .background(DS.Color.canvas)
    }
}

// MARK: - Template Card

private struct TemplateCard: View {
    let title: String
    let items: [String]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(DS.Font.titleM(.semibold))
                    .foregroundStyle(DS.Color.deepCocoa)

                ForEach(items, id: \.self) { item in
                    HStack(spacing: 4) {
                        Text("•")
                            .foregroundStyle(DS.Color.gold)
                        Text(item)
                            .font(DS.Font.caption())
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.m)
                    .fill(DS.Color.background)
            )
        }
        .buttonStyle(.plain)
    }
}
