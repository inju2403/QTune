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
                .dsBodyM(.semibold)
                .foregroundStyle(.secondary)

            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(DS.Color.card.opacity(0.95))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(DS.Color.stroke, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.18), radius: 24, x: 0, y: 14)
                .opacity(reveal ? 1 : 0)
                .offset(y: reveal ? 0 : 20)  // 더 많이 이동
                .scaleEffect(reveal ? 1 : 0.96, anchor: .top)
                .blur(radius: reveal ? 0 : (reduceMotion ? 0 : 4))  // blur 줄임
                .animation(
                    reduceMotion
                        ? .none
                        : .easeOut(duration: 0.7).delay(delay),  // 0.7초로 느리게, easeOut으로 경건한 느낌
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
