//
//  SectionHeader.swift
//  Presentation
//
//  Created by 이승주 on 10/12/25.
//

import SwiftUI
import Domain

/// 섹션 헤더 (아이콘 + 타이틀)
public struct SectionHeader: View {
    let icon: String
    let title: String
    @Environment(\.fontScale) private var fontScale

    public init(icon: String, title: String) {
        self.icon = icon
        self.title = title
    }

    public var body: some View {
        HStack(spacing: DS.Spacing.s) {
            Image(systemName: icon)
                .foregroundStyle(DS.Color.gold)

            DSText.titleM(title)
                .foregroundStyle(DS.Color.textPrimary)

            Spacer()
        }
        .padding(.horizontal, DS.Spacing.m)
    }
}
