//
//  SplashGateView.swift
//  Presentation
//
//  Created by 이승주 on 10/13/25.
//

import SwiftUI

/// 스플래시 → 메인탭 전환 게이트
public struct SplashGateView: View {
    @State private var showMainTab = false

    public init() {}

    public var body: some View {
        ZStack {
            SplashView()
                .opacity(showMainTab ? 0 : 1)
                .zIndex(1)

            if showMainTab {
                Color.clear
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            withAnimation(.easeInOut(duration: 0.5)) {
                showMainTab = true
            }
        }
    }
}
