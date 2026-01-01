//
//  OnboardingState.swift
//  Presentation
//
//  Created by 이승주 on 10/19/25.
//

import Foundation
import Domain

/// 온보딩 화면 State
public struct OnboardingState: Equatable {
    public var nickname: String
    public var selectedGender: UserProfile.Gender
    public var isSaving: Bool
    public var showError: Bool

    public init(
        nickname: String = "",
        selectedGender: UserProfile.Gender = .brother,
        isSaving: Bool = false,
        showError: Bool = false
    ) {
        self.nickname = nickname
        self.selectedGender = selectedGender
        self.isSaving = isSaving
        self.showError = showError
    }
}
