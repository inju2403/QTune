//
//  OnboardingAction.swift
//  Presentation
//
//  Created by 이승주 on 10/19/25.
//

import Foundation
import Domain

/// 온보딩 화면 Action
public enum OnboardingAction: Equatable {
    case updateNickname(String)
    case selectGender(UserProfile.Gender)
    case saveProfile
}
