//
//  VerseCardView.swift
//  Presentation
//
//  Created by 이승주 on 10/12/25.
//

import SwiftUI

/// 말씀/해설/추천 이유 카드
public struct VerseCardView<Content: View>: View {
    let title: String?
    @ViewBuilder var content: Content

    public init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            if let title {
                Text(title)
                    .dsBodyM(.semibold)
                    .foregroundStyle(DS.Color.textSecondary)
            }

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.l)
                .fill(DS.Color.canvas)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.l)
                        .stroke(DS.Color.divider, lineWidth: 1)
                )
        )
        .dsShadow(DS.Shadow.card)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(Motion.appear, value: title)
    }
}
