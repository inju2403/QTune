//
//  WarmGradientBackground.swift
//  Presentation
//
//  Created by 이승주 on 10/19/25.
//

import SwiftUI

/// 따뜻한 베이지 그라데이션 배경 (RequestVerseView 전용)
public struct WarmGradientBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    public init() {}

    public var body: some View {
        ZStack {
            // 매우 밝은 베이지 배경 (거의 흰색)
            Color(hex: "#FAF8F6")
                .ignoresSafeArea()

            // 미묘한 그라데이션
            LinearGradient(
                colors: [
                    Color.white.opacity(0.3),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()

            // 종이 텍스처
            Color.white
                .opacity(0.015)
                .blendMode(.overlay)
                .ignoresSafeArea()
        }
    }
}
