//
//  PrayerLoader.swift
//  Presentation
//
//  Created by 이승주 on 10/13/25.
//

import SwiftUI

/// 십자가 + 햇살 펄스 로더
public struct PrayerLoader: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var spin = false
    @State private var pulse = false

    public init() {}

    public var body: some View {
        ZStack {
            // 금빛 햇살 펄스
            Circle()
                .fill(DSColor.gold.opacity(0.25))
                .frame(width: 140, height: 140)
                .scaleEffect(pulse ? 1.05 : 0.9)
                .blur(radius: 12)
                .animation(
                    reduceMotion ? .none : .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                    value: pulse
                )

            // 십자가 글리프
            CrossGlyph()
                .stroke(DSColor.cocoaDeep.opacity(0.7), lineWidth: 2.5)
                .frame(width: 44, height: 44)
                .rotationEffect(.degrees(spin ? 360 : 0))
                .animation(
                    reduceMotion ? .none : .linear(duration: 1.6).repeatForever(autoreverses: false),
                    value: spin
                )
        }
        .onAppear {
            pulse = true
            spin = true
        }
        .accessibilityLabel("말씀을 준비하는 중")
    }
}

/// 십자가 글리프 Shape
struct CrossGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let centerX = w * 0.5
        let centerY = h * 0.5

        // 세로 막대
        path.addRoundedRect(
            in: CGRect(x: centerX - 3, y: centerY - 18, width: 6, height: 36),
            cornerSize: CGSize(width: 2, height: 2)
        )

        // 가로 막대
        path.addRoundedRect(
            in: CGRect(x: centerX - 16, y: centerY - 3, width: 32, height: 6),
            cornerSize: CGSize(width: 2, height: 2)
        )

        return path
    }
}
