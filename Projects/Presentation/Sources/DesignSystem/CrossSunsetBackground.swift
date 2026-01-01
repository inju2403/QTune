//
//  CrossSunsetBackground.swift
//  Presentation
//
//  Created by 이승주 on 10/13/25.
//

import SwiftUI

/// 노을 배경
public struct CrossSunsetBackground: View {
    public init() {}

    public var body: some View {
        ZStack {
            // 노을 그라데이션 3층
            LinearGradient(
                colors: [DS.Color.bgTop, DS.Color.bgMid],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()

            LinearGradient(
                colors: [DS.Color.bgMid, DS.Color.bgBot],
                startPoint: .center,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // 햇살(라디얼) – 하단 은은한 광량
            RadialGradient(
                colors: [
                    DS.Color.gold.opacity(0.35),
                    DS.Color.gold.opacity(0.08),
                    .clear
                ],
                center: .bottom,
                startRadius: 10,
                endRadius: 420
            )
            .offset(y: 120)

            // 종이결 텍스처
            Color.white
                .opacity(0.03)
                .blendMode(.overlay)
                .ignoresSafeArea()
        }
    }
}

/// 십자가 Shape
struct CrossSilhouette: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let centerX = width * 0.5
        let centerY = height * 0.42

        // 세로 막대
        path.addRoundedRect(
            in: CGRect(x: centerX - 10, y: centerY - 140, width: 20, height: 260),
            cornerSize: CGSize(width: 8, height: 8)
        )

        // 가로 막대 (약간 위)
        path.addRoundedRect(
            in: CGRect(x: centerX - 90, y: centerY - 40, width: 180, height: 18),
            cornerSize: CGSize(width: 8, height: 8)
        )

        return path
    }
}
