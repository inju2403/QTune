//
//  MyPageState.swift
//  Presentation
//
//  Created by 이승주 on 1/15/26.
//

import Foundation
import Domain

/// 마이페이지 State
public struct MyPageState: Equatable {
    public var showVersionAlert: Bool
    public var showTranslationSelection: Bool
    public var selectedPrimaryTranslation: Translation
    public var selectedSecondaryTranslation: Translation?

    public init(
        showVersionAlert: Bool = false,
        showTranslationSelection: Bool = false,
        selectedPrimaryTranslation: Translation = .koreanRevisedVersion,
        selectedSecondaryTranslation: Translation? = nil
    ) {
        self.showVersionAlert = showVersionAlert
        self.showTranslationSelection = showTranslationSelection
        self.selectedPrimaryTranslation = selectedPrimaryTranslation
        self.selectedSecondaryTranslation = selectedSecondaryTranslation
    }
}
