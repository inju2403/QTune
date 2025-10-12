//
//  SoftCard.swift
//  Presentation
//
//  Created by 이승주 on 10/12/25.
//

import SwiftUI

/// 리스트 셀/입력 카드용 소프트 카드
public struct SoftCard<Content: View>: View {
    @ViewBuilder var content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(DS.Spacing.l)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.m)
                    .fill(DS.Color.canvas)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.m)
                            .stroke(DS.Color.divider, lineWidth: 1)
                    )
            )
            .dsShadow(DS.Shadow.soft)
    }
}
