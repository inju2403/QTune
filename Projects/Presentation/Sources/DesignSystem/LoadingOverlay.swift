//
//  LoadingOverlay.swift
//  Presentation
//
//  Created by 이승주 on 10/13/25.
//

import SwiftUI

/// 중앙 로딩 오버레이 (PrayerLoader + 메시지)
public struct LoadingOverlay: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 14) {
            PrayerLoader()

            Text("말씀을 기도로 준비하는 중…")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(DSColor.cocoa)
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(DSColor.stroke, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 8)
    }
}
