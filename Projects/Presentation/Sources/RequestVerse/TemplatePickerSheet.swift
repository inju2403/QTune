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

            // Title
            VStack(spacing: 8) {
                Text("오늘 어떤 방식으로")
                    .font(DS.Font.titleM(.semibold))
                    .foregroundStyle(DS.Color.deepCocoa)
                Text("말씀을 묵상하고 싶으신가요?")
                    .font(DS.Font.titleM(.semibold))
                    .foregroundStyle(DS.Color.deepCocoa)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)

            // Template cards
            VStack(spacing: 12) {
                TemplateCard(
                    title: "SOAP",
                    description: "말씀을 차분히 이해하고, 오늘의 삶에 연결하는 묵상",
                    bullets: [
                        "말씀에서 눈에 들어온 표현을 살펴봐요",
                        "이 말씀이 삶과 어떻게 이어지는지 생각해요",
                        "느낀 점과 바람을 정리해요"
                    ],
                    footerGuide: "📘 생각을 정리하며 묵상하고 싶을 때"
                ) {
                    Haptics.tap()
                    onSelect(.soap)
                    dismiss()
                }

                TemplateCard(
                    title: "ACTS",
                    description: "마음을 돌아보며 기도로 이어가는 묵상",
                    bullets: [
                        "말씀 속 메시지와 가치를 느껴봐요",
                        "나의 모습과 마음을 돌아봐요",
                        "감사와 바람을 솔직하게 적어요",
                        "앞으로의 도움을 정리해요"
                    ],
                    footerGuide: "💭 마음을 풀어놓고 묵상하고 싶을 때"
                ) {
                    Haptics.tap()
                    onSelect(.acts)
                    dismiss()
                }
            }
            .padding(.horizontal, 20)

            // Note
            Text("선택 후에도 언제든 다른 방식으로 다시 묵상할 수 있어요.")
                .font(DS.Font.caption())
                .foregroundStyle(DS.Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
        }
        .padding(.bottom, 12)
        .background(DS.Color.canvas)
    }
}

// MARK: - Template Card

private struct TemplateCard: View {
    let title: String
    let description: String
    let bullets: [String]
    let footerGuide: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Title
                Text(title)
                    .font(DS.Font.titleM(.bold))
                    .foregroundStyle(DS.Color.deepCocoa)

                // Description
                Text(description)
                    .font(DS.Font.bodyM())
                    .foregroundStyle(DS.Color.textPrimary)
                    .lineSpacing(4)

                // Bullets
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(bullets, id: \.self) { bullet in
                        HStack(alignment: .top, spacing: 6) {
                            Text("•")
                                .font(DS.Font.caption())
                                .foregroundStyle(DS.Color.gold)
                            Text(bullet)
                                .font(DS.Font.caption())
                                .foregroundStyle(DS.Color.textSecondary)
                                .lineSpacing(2)
                        }
                    }
                }
                .padding(.top, 4)

                // Footer Guide
                Text(footerGuide)
                    .font(DS.Font.caption(.medium))
                    .foregroundStyle(DS.Color.gold.opacity(0.9))
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.m)
                    .fill(DS.Color.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.m)
                            .stroke(DS.Color.gold.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
