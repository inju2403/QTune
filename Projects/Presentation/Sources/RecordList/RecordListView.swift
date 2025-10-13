//
//  RecordListView.swift
//  Presentation
//
//  Created by 이승주 on 10/13/25.
//

import SwiftUI

/// 기록 리스트 뷰 (QTListView 래퍼)
public struct RecordListView: View {
    public init() {}

    public var body: some View {
        // QTListView를 그대로 활용
        // 실제 앱에서는 DI를 통해 viewModel 주입
        Text("RecordListView")
            .font(.largeTitle)
            .foregroundStyle(DSColor.textPri)
            .navigationTitle("기록")
    }
}
