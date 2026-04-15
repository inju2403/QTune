//
//  TemplatePickerSheet.swift
//  Presentation
//
//  Created by 이승주 on 10/19/25.
//

import SwiftUI
import Domain

/// 템플릿 선택 바텀시트 (SOAP / ACTS / 자유 묵상)
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
                .padding(.bottom, 20)

            // Title
            VStack(spacing: 4) {
                DSText.titleM("오늘 어떤 방식으로", weight: .semibold)
                    .foregroundStyle(DS.Color.deepCocoa)
                DSText.titleM("묵상하고 싶으신가요?", weight: .semibold)
                    .foregroundStyle(DS.Color.deepCocoa)
            }
            .multilineTextAlignment(.center)
            .padding(.bottom, 20)

            // 3개 카드 — 균등 분배로 화면 꽉 채우기
            VStack(spacing: 10) {
                TemplateCard(
                    icon: "book.closed.fill",
                    title: "SOAP",
                    subtitle: "말씀의 본질에 집중",
                    description: "말씀을 관찰하고, 적용점을 찾아 기도로 마무리하는 체계적인 묵상",
                    accentColor: DS.Color.gold
                ) {
                    Haptics.tap()
                    onSelect(.soap)
                    dismiss()
                }

                TemplateCard(
                    icon: "hands.sparkles.fill",
                    title: "ACTS",
                    subtitle: "기도로 시작하는 묵상",
                    description: "찬양, 고백, 감사, 간구의 흐름으로 하나님께 나아가는 기도 묵상",
                    accentColor: DS.Color.gold
                ) {
                    Haptics.tap()
                    onSelect(.acts)
                    dismiss()
                }

                TemplateCard(
                    icon: "heart.text.square.fill",
                    title: "자유 묵상",
                    subtitle: "나만의 방식으로",
                    description: "정해진 형식 없이, 오늘 말씀에서 받은 은혜를 자유롭게 기록",
                    accentColor: DS.Color.gold
                ) {
                    Haptics.tap()
                    onSelect(.free)
                    dismiss()
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
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
    let accentColor: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                // 상단: 아이콘 + 제목 + 부제
                HStack(spacing: 14) {
                    // 아이콘 (accent 배경 원)
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.12))
                            .frame(width: 44, height: 44)

                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(accentColor)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        DSText.bodyL(title, weight: .bold)
                            .foregroundStyle(DS.Color.deepCocoa)
                        DSText.caption(subtitle)
                            .foregroundStyle(DS.Color.textSecondary)
                    }

                    Spacer()

                    // 선택 pill
                    Text("선택")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(accentColor)
                        )
                }

                Spacer(minLength: 10)

                // 설명
                DSText.bodyM(description)
                    .foregroundStyle(DS.Color.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(DS.Color.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(accentColor.opacity(0.15), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(CardPressStyle(isPressed: $isPressed))
    }
}

// MARK: - Card Press Style (눌림 피드백)

private struct CardPressStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
    }
}
