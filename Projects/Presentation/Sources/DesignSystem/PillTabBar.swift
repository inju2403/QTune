//
//  PillTabBar.swift
//  Presentation
//
//  Created by 이승주 on 10/12/25.
//

import SwiftUI

/// 하단 캡슐 탭바
public struct PillTabBar: View {
    @Binding var selection: Int

    public init(selection: Binding<Int>) {
        self._selection = selection
    }

    public var body: some View {
        HStack(spacing: DS.Spacing.l) {
            tab(icon: "sparkles", title: "오늘의 말씀", index: 0)
            tab(icon: "book", title: "기록", index: 1)
        }
        .padding(DS.Spacing.m)
        .background(
            ZStack {
                Capsule()
                    .fill(.ultraThinMaterial)

                // Glossy top highlight
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.25), .white.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
            }
        )
        .overlay(
            Capsule()
                .stroke(DSColor.gold.opacity(0.35), lineWidth: 1.5)
        )
        .glow(DSColor.gold)
        .padding(.bottom, DS.Spacing.l)
        .padding(.horizontal, DS.Spacing.xl)
        .shadow(color: .black.opacity(0.25), radius: 22, x: 0, y: 12)
    }

    private func tab(icon: String, title: String, index: Int) -> some View {
        Button {
            Haptics.tap()
            withAnimation(Motion.appear) {
                selection = index
            }
        } label: {
            HStack(spacing: DS.Spacing.s) {
                Image(systemName: icon)
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .padding(.vertical, DS.Spacing.s)
            .padding(.horizontal, DS.Spacing.l)
            .background(
                Group {
                    if selection == index {
                        Capsule()
                            .fill(DSColor.gold.opacity(0.25))
                            .overlay(
                                Capsule()
                                    .stroke(DSColor.gold.opacity(0.6), lineWidth: 1)
                            )
                    } else {
                        Color.clear
                    }
                }
            )
        }
        .foregroundStyle(
            selection == index ? .white.opacity(0.95) : DSColor.textSec
        )
        .scaleEffect(selection == index ? 1.02 : 1)
        .animation(Motion.press, value: selection)
    }
}
