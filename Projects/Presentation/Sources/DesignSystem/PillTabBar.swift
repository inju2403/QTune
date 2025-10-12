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
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(DS.Color.divider, lineWidth: 1))
        .padding(.bottom, DS.Spacing.l)
        .padding(.horizontal, DS.Spacing.xl)
        .dsShadow(.init(color: .black.opacity(0.12), radius: 18, y: 10))
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
                    .font(DS.Font.bodyM(.semibold))
            }
            .padding(.vertical, DS.Spacing.s)
            .padding(.horizontal, DS.Spacing.l)
            .background(
                selection == index ? DS.Color.sand.opacity(0.6) : .clear,
                in: Capsule()
            )
            .overlay {
                if selection == index {
                    Capsule()
                        .stroke(DS.Color.gold.opacity(0.5), lineWidth: 1)
                }
            }
        }
        .foregroundStyle(
            selection == index ? DS.Color.deepCocoa : DS.Color.textSecondary
        )
    }
}
