//
//  RecommendFlowView.swift
//  Presentation
//
//  Created by 이승주 on 10/13/25.
//

import SwiftUI
import Domain

/// 추천 플로우 래퍼 (RequestVerseView 활용)
public struct RecommendFlowView: View {
    @State private var path = NavigationPath()

    public init() {}

    public var body: some View {
        // RequestVerseView를 그대로 활용
        // 실제 앱에서는 DI를 통해 viewModel 주입
        Text("RecommendFlowView")
            .font(.largeTitle)
            .foregroundStyle(DSColor.textPri)
    }
}
