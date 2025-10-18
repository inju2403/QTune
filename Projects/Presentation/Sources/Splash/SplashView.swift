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
    @State private var showText = false

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

            // 텍스트 카피
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 8) {
                    // 한줄 카피
                    Text("주의 말씀은 내 발에 등이요")
                        .font(.system(size: 20, weight: .semibold, design: .default))
                        .foregroundStyle(DSColor.cocoa.opacity(0.9))
                        .multilineTextAlignment(.center)

                    // 보조 카피
                    Text("Your word is a lamp to my feet. (Ps 119:105)")
                        .font(.system(size: 14, weight: .regular, design: .default))
                        .foregroundStyle(DSColor.cocoa.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .opacity(reduceMotion || showText ? 1 : 0)
                .offset(y: reduceMotion || showText ? 0 : 6)

                Spacer()
                    .frame(height: 120)
            }
            .padding(.horizontal, 32)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("QTune. 주의 말씀은 내 발에 등이요. Your word is a lamp to my feet. 잠시 후 메인 화면으로 이동합니다.")
        .onAppear {
            if !reduceMotion {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeOut(duration: 0.6)) {
                        showText = true
                    }
                }
            }
        }
    }
}
