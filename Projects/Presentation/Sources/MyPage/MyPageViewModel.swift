//
//  MyPageViewModel.swift
//  Presentation
//
//  Created by 이승주 on 1/15/26.
//

import Foundation
import SwiftUI

/// 마이페이지 ViewModel
@Observable
public final class MyPageViewModel {
    // MARK: - State
    public private(set) var state: MyPageState

    // MARK: - Callbacks
    public var onProfileEdit: (() -> Void)?
    public var onOpenURL: ((URL) -> Void)?

    // MARK: - Init
    public init(initialState: MyPageState = MyPageState()) {
        self.state = initialState
    }

    // MARK: - Send Action
    public func send(_ action: MyPageAction) {
        switch action {
        case .tapProfileEdit:
            onProfileEdit?()

        case .tapImprovement:
            if let url = URL(string: "https://docs.google.com/forms/d/e/1FAIpQLSfzUt_GdAoPGt8ZjGOzsAdtgc6LAK1MPQc2Iu_6izpYB0OlrQ/viewform") {
                onOpenURL?(url)
            }

        case .tapReview:
            if let url = URL(string: "https://apps.apple.com/kr/app/id6757230938?action=write-review") {
                onOpenURL?(url)
            }

        case .tapPrivacyPolicy:
            if let url = URL(string: "https://github.com/inju2403/QTune/blob/dev/privacy-policy.md") {
                onOpenURL?(url)
            }

        case .tapVersionInfo:
            state.showVersionAlert = true

        case .dismissVersionAlert:
            state.showVersionAlert = false
        }
    }
}
