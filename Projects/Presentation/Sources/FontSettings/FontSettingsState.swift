//
//  FontSettingsState.swift
//  Presentation
//
//  Created by 이승주 on 2/6/26.
//

import Foundation
import Domain

/// 폰트 설정 State
public struct FontSettingsState: Equatable {
    public var selectedFontScale: FontScale
    public var selectedLineSpacing: LineSpacing
    public var isSaving: Bool

    public init(
        selectedFontScale: FontScale = .medium,
        selectedLineSpacing: LineSpacing = .normal,
        isSaving: Bool = false
    ) {
        self.selectedFontScale = selectedFontScale
        self.selectedLineSpacing = selectedLineSpacing
        self.isSaving = isSaving
    }
}
