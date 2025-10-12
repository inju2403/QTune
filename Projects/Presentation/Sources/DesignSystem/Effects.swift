//
//  Effects.swift
//  Presentation
//
//  Created by 이승주 on 10/13/25.
//

import SwiftUI

// MARK: - Shimmer Effect
public struct Shimmer: ViewModifier {
    @State private var phase: CGFloat = -1

    public func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .white.opacity(0.0),
                        .white.opacity(0.35),
                        .white.opacity(0.0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(20))
                .offset(x: phase * 220)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 2.2).repeatForever(autoreverses: false)) {
                    phase = 1.2
                }
            }
    }
}

extension View {
    public func shimmer() -> some View {
        modifier(Shimmer())
    }
}

// MARK: - Glow Effect
public struct Glow: ViewModifier {
    var color: Color = DSColor.gold

    public func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.35), radius: 12, x: 0, y: 0)
            .shadow(color: color.opacity(0.18), radius: 24, x: 0, y: 0)
    }
}

extension View {
    public func glow(_ color: Color = DSColor.gold) -> some View {
        modifier(Glow(color: color))
    }
}
