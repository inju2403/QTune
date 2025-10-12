//
//  CrossSunsetBackground.swift
//  Presentation
//
//  Created by 이승주 on 10/13/25.
//

import SwiftUI

/// 노을 + 십자가 실루엣 배경
public struct CrossSunsetBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathingPhase: CGFloat = 0

    public init() {}

    public var body: some View {
        ZStack {
            // 노을 그라데이션 3층
            LinearGradient(
                colors: [DSColor.bgTop, DSColor.bgMid],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()

            LinearGradient(
                colors: [DSColor.bgMid, DSColor.bgBottom],
                startPoint: .center,
                endPoint: .bottom
            )
            .blendMode(.multiply)
            .ignoresSafeArea()

            // 해(라디얼) – 숨쉬듯 브레싱
            RadialGradient(
                colors: [
                    DSColor.sunCore.opacity(0.55),
                    DSColor.sunEdge.opacity(0.15),
                    .clear
                ],
                center: .center,
                startRadius: 40,
                endRadius: 480
            )
            .scaleEffect(1 + (reduceMotion ? 0 : 0.015 * sin(breathingPhase)))
            .animation(
                reduceMotion ? .none : .easeInOut(duration: 2.4).repeatForever(autoreverses: true),
                value: breathingPhase
            )
            .onAppear {
                breathingPhase = 1
            }

            // 십자가 실루엣
            CrossSilhouette()
                .fill(Color.black.opacity(0.28))
                .blur(radius: 1)
                .scaleEffect(1.05)
                .offset(y: -18)
                .allowsHitTesting(false)

            // 종이결 텍스처 (optional - will work without image too)
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
