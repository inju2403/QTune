//
//  PrimaryCTAButton.swift
//  Presentation
//
//  Created by 이승주 on 10/13/25.
//

import SwiftUI
import Domain

/// CTA 버튼 with 광채 + 립플 + 3D effect
public struct PrimaryCTAButton: View {
    public enum Style {
        case primary  // 기존 브라운/골드
        case success  // 녹색 (은혜로운 톤)
    }

    let title: String
    var icon: String = "sparkles"
    var style: Style = .primary
    var action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.fontScale) private var fontScale
    @State private var press = false
    @State private var ripple = false

    public init(title: String, icon: String = "sparkles", style: Style = .primary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }

    public var body: some View {
        Button {
            Haptics.tap()
            if !reduceMotion {
                ripple.toggle()
            }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85, blendDuration: 0.15)) {
                action()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                DSText.bodyL(title, weight: .semibold)
            }
            .foregroundStyle(.white)
            .padding(.vertical, 16)
            .padding(.horizontal, 28)
            .background(
                LinearGradient(
                    colors: style == .success ? [
                        Color(hex: "#77C593"),
                        Color(hex: "#4AAE7B")
                    ] : [
                        DS.Color.accent.opacity(0.95),
                        DS.Color.accent,
                        DS.Color.accent2
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    LinearGradient(
                        colors: [.white.opacity(0.2), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .overlay(
                // 립플 하이라이트
                Circle()
                    .stroke((style == .success ? Color(hex: "#77C593") : DS.Color.gold).opacity(ripple ? 0 : 0.5), lineWidth: 2)
                    .scaleEffect(ripple ? 3.2 : 0.1)
                    .opacity(ripple ? 0 : 1)
                    .blendMode(.screen)
                    .animation(reduceMotion ? .none : .easeOut(duration: 0.7), value: ripple)
            )
            .shadow(color: .black.opacity(style == .success ? 0.15 : 0.1), radius: 8, y: 4)
            .glow(style == .success ? Color(hex: "#77C593") : DS.Color.gold)
            .scaleEffect(press ? 0.98 : 1)
        }
        .accessibilityHint("추천 결과가 아래에 펼쳐집니다")
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.9)) {
                        press = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        press = false
                    }
                }
        )
    }
}
