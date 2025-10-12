//
//  ExpandableCard.swift
//  Presentation
//
//  Created by 이승주 on 10/13/25.
//

import SwiftUI

/// 쫘르륵 펼쳐지는 아코디언 카드
public struct ExpandableCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    var delay: Double = 0

    @State private var reveal = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(title: String, delay: Double = 0, @ViewBuilder content: () -> Content) {
        self.title = title
        self.delay = delay
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)

            content
                .font(.system(size: 17))
                .foregroundStyle(DSColor.textPri)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(DSColor.card.opacity(0.95))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(.black.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.15), radius: 22, x: 0, y: 12)
                .opacity(reveal ? 1 : 0)
                .offset(y: reveal ? 0 : 12)
                .blur(radius: reveal ? 0 : (reduceMotion ? 0 : 8))
                .animation(
                    reduceMotion
                        ? .none
                        : .spring(response: 0.48, dampingFraction: 0.86).delay(delay),
                    value: reveal
                )
                .onAppear {
                    reveal = true
                }
        }
    }
}

/// Result phase for state machine
public enum ResultPhase {
    case idle
    case loading
    case expanding
    case expanded
}
