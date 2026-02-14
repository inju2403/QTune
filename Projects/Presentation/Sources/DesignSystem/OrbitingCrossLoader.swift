//
//  OrbitingCrossLoader.swift
//  Presentation
//
//  Created by 이승주 on 10/17/25.
//

import SwiftUI
import Domain

// MARK: - Wood Cross Pulse Loader

/// 고퀄 목재 십자가가 은은히 나타났다 사라지는 로더
public struct QTuneWoodCrossPulse: View {
    public var size: CGFloat = 84                // 기본 크기 (작고 단정)
    public var minOpacity: Double = 0.35
    public var maxOpacity: Double = 1.0
    public var duration: Double = 1.4            // 페이드 주기

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var on = false

    public init(size: CGFloat = 84) { self.size = size }

    public var body: some View {
        WoodCrossBeveled()
            .frame(width: size, height: size * 1.25)         // 세로가 더 길게
            .scaleEffect(reduceMotion ? 1.0 : (on ? 1.015 : 0.985))
            .opacity(reduceMotion ? 1.0 : (on ? maxOpacity : minOpacity))
            .animation(.easeInOut(duration: duration).repeatForever(autoreverses: true), value: on)
            .onAppear { on = true }
            .accessibilityHidden(true)
    }
}

/// 목재 질감/하이라이트/그림자를 합성한 십자가 (세로길고 좌우 짧음)
private struct WoodCrossBeveled: View {
    // Bronze Gold
    private let woodDark = Color(red: 0.43, green: 0.32, blue: 0.18)
    private let wood     = Color(red: 0.58, green: 0.43, blue: 0.22)
    private let woodLite = Color(red: 0.76, green: 0.60, blue: 0.34)

    var body: some View {
        GeometryReader { geo in
            let W = geo.size.width
            let H = geo.size.height

            // 비율: 팔 두께 t, 수평 길이 hLen, 수직 길이 vLen
            let t     = min(W, H) * 0.22          // 팔 두께 (굵게)
            let vLen  = H                          // 세로 전체
            let hLen  = W * 0.85                   // 가로는 짧게
            let armY  = H * 0.38                   // 가로 팔 위치(위쪽으로)
            let radius = t * 0.22                  // 모서리 라운드

            ZStack {
                // === 몸통 기본(목재 그라디언트) ===
                // 세로 바디
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(LinearGradient(
                        colors: [woodLite, wood, woodDark],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: t, height: vLen)
                    .position(x: W/2, y: H/2)

                // 가로 팔
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(LinearGradient(
                        colors: [woodLite, wood, woodDark],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: hLen, height: t)
                    .position(x: W/2, y: armY)

                // === 베벨(사선 하이라이트) ===
                // 세로 바디 하이라이트
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: [
                            Color.white.opacity(0.35),
                            .clear
                        ], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: t * 0.14
                    )
                    .frame(width: t, height: vLen)
                    .blendMode(.plusLighter)
                    .position(x: W/2, y: H/2)

                // 가로 팔 하이라이트
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: [
                            Color.white.opacity(0.30),
                            .clear
                        ], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: t * 0.14
                    )
                    .frame(width: hLen, height: t)
                    .blendMode(.plusLighter)
                    .position(x: W/2, y: armY)

                // === 내측 음영(깊이감) ===
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: [
                            .clear,
                            Color.black.opacity(0.12)
                        ], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: t * 0.10
                    )
                    .frame(width: t, height: vLen)
                    .position(x: W/2, y: H/2)

                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: [
                            .clear,
                            Color.black.opacity(0.10)
                        ], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: t * 0.10
                    )
                    .frame(width: hLen, height: t)
                    .position(x: W/2, y: armY)
            }
            // 외곽 드롭섀도우 (바닥에 살짝 떨어진 느낌)
            .shadow(color: Color.black.opacity(0.15), radius: t * 0.35, x: 0, y: t * 0.25)
        }
    }
}

/// 십자가 페이드 로딩 오버레이
public struct QTuneCrossOverlay: View {
    public var message: String = "말씀을 기도로 준비하는 중"
    public var size: CGFloat = 84

    @Environment(\.fontScale) private var fontScale

    public init() {}

    public var body: some View {
        ZStack {
            Color.black.opacity(0.06).ignoresSafeArea()

            VStack(spacing: 24) {
                QTuneWoodCrossPulse(size: size)    // ✝️ 고퀄 십자가
                DSText.bodyM(message, weight: .semibold)
                    .foregroundStyle(Color.black.opacity(0.82))
                    .multilineTextAlignment(.center)
                    .padding(.top, 2)
            }
            .padding(.vertical, 22)
            .padding(.horizontal, 26)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white.opacity(0.98))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.black.opacity(0.06), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.12), radius: 18, y: 10)
            )
        }
        .transition(.opacity)
        .accessibilityAddTraits(.isModal)
    }
}
