//
//  PrimaryButton.swift
//  Presentation
//
//  Created by 이승주 on 10/12/25.
//

import SwiftUI
import Domain

/// 주요 액션 버튼 - 광채 + 스르륵
public struct PrimaryButton: View {
    let title: String
    var icon: String?
    var action: () -> Void

    @State private var pressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.fontScale) private var fontScale

    public init(title: String, icon: String? = "sparkles", action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    public var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: DS.Spacing.m) {
                if let icon, !icon.isEmpty {
                    Image(systemName: icon)
                }
                DSText.titleM(title)
            }
            .padding(.vertical, DS.Spacing.m)
            .padding(.horizontal, DS.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.pill)
                    .fill(
                        LinearGradient(
                            colors: [DS.Color.olive, DS.Color.success],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.pill)
                    .stroke(DS.Color.gold.opacity(0.4), lineWidth: 1)
            )
            .foregroundStyle(.white)
            .scaleEffect(pressed ? 0.98 : 1)
            .dsShadow(.init(color: .black.opacity(0.18), radius: 24, y: 12))
            .overlay(alignment: .topTrailing) {
                // 은은한 하이라이트
                if !reduceMotion {
                    Circle()
                        .fill(DS.Color.gold.opacity(0.25))
                        .frame(width: 36, height: 36)
                        .offset(x: 10, y: -10)
                        .blur(radius: 10)
                }
            }
        }
        .pressEvents { isPressed in
            withAnimation(Motion.press) {
                pressed = isPressed
            }
        }
    }
}

// MARK: - Press Events Helper
extension View {
    func pressEvents(onPress: @escaping (Bool) -> Void) -> some View {
        modifier(PressEventsModifier(onPress: onPress))
    }
}

struct PressEventsModifier: ViewModifier {
    let onPress: (Bool) -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress(true) }
                    .onEnded { _ in onPress(false) }
            )
    }
}
