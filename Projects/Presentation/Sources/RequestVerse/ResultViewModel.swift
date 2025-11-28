//
//  ResultViewModel.swift
//  Presentation
//
//  Created by 이승주 on 11/28/25.
//

import Foundation
import SwiftUI
import Domain

/// 추천 결과 화면 ViewModel
@Observable
public final class ResultViewModel {
    // MARK: - State
    public private(set) var state: ResultState

    // MARK: - Callbacks
    public var onNavigateToEditor: ((TemplateKind) -> Void)?

    // MARK: - Init
    public init(initialState: ResultState) {
        self.state = initialState
    }

    // MARK: - Send Action
    public func send(_ action: ResultAction) {
        switch action {
        case .tapGoToQT:
            state.showTemplateSheet = true
        case .selectTemplate(let template):
            state.showTemplateSheet = false
            // 0.1초 후 네비게이션 (Sheet 닫히는 애니메이션 대기)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.onNavigateToEditor?(template)
            }
        case .dismissSheet:
            state.showTemplateSheet = false
        }
    }
}
