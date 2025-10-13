//
//  SplashView.swift
//  Presentation
//
//  Created by 이승주 on 10/13/25.
//

import SwiftUI

/// 스플래시 화면
public struct SplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathe = false

    public init() {}

    public var body: some View {
        ZStack {
            // 스플래시 배경 이미지
            Image("QTune_Splash")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // 브리딩 하이라이트 (Reduce Motion 시 비활성화)
            if !reduceMotion {
                Circle()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 250, height: 250)
                    .blur(radius: 40)
                    .offset(y: 80)
                    .scaleEffect(breathe ? 1.05 : 0.95)
                    .opacity(breathe ? 0.8 : 0.4)
                    .animation(
                        .easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                        value: breathe
                    )
                    .onAppear {
                        breathe = true
                    }
            }
        }
    }
}
