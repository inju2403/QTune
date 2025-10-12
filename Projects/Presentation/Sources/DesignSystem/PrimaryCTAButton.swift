//
//  PrimaryCTAButton.swift
//  Presentation
//
//  Created by 이승주 on 10/13/25.
//

import SwiftUI

/// CTA 버튼 with 광채 + 립플 + 3D effect
public struct PrimaryCTAButton: View {
    let title: String
    var icon: String = "sparkles"
    var action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var press = false
    @State private var ripple = false

    public init(title: String, icon: String = "sparkles", action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
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
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white)
            .padding(.vertical, 16)
            .padding(.horizontal, 28)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [DSColor.accent, DSColor.accent2],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                // 립플 하이라이트
                Circle()
                    .stroke(DSColor.gold.opacity(ripple ? 0 : 0.5), lineWidth: 2)
                    .scaleEffect(ripple ? 3.2 : 0.1)
                    .opacity(ripple ? 0 : 1)
                    .blendMode(.screen)
                    .animation(reduceMotion ? .none : .easeOut(duration: 0.7), value: ripple)
            )
            .glow(DSColor.gold)
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
