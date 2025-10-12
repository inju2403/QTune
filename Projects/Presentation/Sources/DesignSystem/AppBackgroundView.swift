//
//  AppBackgroundView.swift
//  Presentation
//
//  Created by 이승주 on 10/12/25.
//

import SwiftUI

/// 은혜로운 배경 - 십자가 워터마크 + 그라데이션 + 패럴랙스
public struct AppBackgroundView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init() {}

    public var body: some View {
        ZStack {
            // 기본 그라데이션
            LinearGradient(
                colors: [DS.Color.background, DS.Color.sand],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // 은은한 십자가 워터마크
            CrossWatermark()
                .foregroundStyle(DS.Color.sand.opacity(0.55))
                .scaleEffect(1.3)
                .blur(radius: 10)
                .opacity(0.25)
                .offset(y: -40)

            // 금빛 빛무리
            RadialGradient(
                colors: [.clear, DS.Color.gold.opacity(0.15)],
                center: .center,
                startRadius: 10,
                endRadius: 420
            )
            .blendMode(.softLight)
            .ignoresSafeArea()
            .opacity(0.9)

            // 미세한 패럴랙스 입자 (모션 축소 시 비활성)
            if !reduceMotion {
                StarsLayer()
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
    }
}

// MARK: - Cross Watermark
private struct CrossWatermark: View {
    var body: some View {
        ZStack {
            // 세로 막대
            RoundedRectangle(cornerRadius: DS.Radius.s)
                .frame(width: 18, height: 220)

            // 가로 막대
            RoundedRectangle(cornerRadius: DS.Radius.s)
                .frame(width: 160, height: 18)
                .offset(y: -42)
        }
    }
}

// MARK: - Stars Layer (패럴랙스 입자)
private struct StarsLayer: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        TimelineView(.animation) { context in
            Canvas { graphicsContext, size in
                let time = phase + context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 10) / 10

                for i in 0..<40 {
                    var x = CGFloat(i * 37 % Int(size.width))
                    let y = CGFloat(i * 59 % Int(size.height))
                    x += sin(CGFloat(i) + time * 2) * 6

                    let dot = Path(ellipseIn: CGRect(x: x, y: y, width: 2, height: 2))
                    graphicsContext.fill(dot, with: .color(.white.opacity(0.06)))
                }
            }
        }
    }
}
