//
//  FontSettingsViewModel.swift
//  Presentation
//
//  Created by 이승주 on 2/6/26.
//

import Foundation
import Domain

@Observable
public final class FontSettingsViewModel {
    public private(set) var state: FontSettingsState

    private let saveProfileUseCase: SaveUserProfileUseCase

    public init(
        initialFontScale: FontScale,
        initialLineSpacing: LineSpacing,
        saveProfileUseCase: SaveUserProfileUseCase
    ) {
        self.state = FontSettingsState(
            selectedFontScale: initialFontScale,
            selectedLineSpacing: initialLineSpacing
        )
        self.saveProfileUseCase = saveProfileUseCase
    }

    public func send(_ action: FontSettingsAction) {
        switch action {
        case .selectFontScale(let scale):
            state.selectedFontScale = scale

        case .selectLineSpacing(let spacing):
            state.selectedLineSpacing = spacing

        case .save:
            state.isSaving = true
            // 저장은 View에서 UserProfile 전체를 업데이트해서 수행

        case .saveCompleted:
            state.isSaving = false
        }
    }
}
