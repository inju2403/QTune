//
//  MyPageAction.swift
//  Presentation
//
//  Created by 이승주 on 1/15/26.
//

import Foundation
import Domain

/// 마이페이지 Action
public enum MyPageAction: Equatable {
    case tapProfileEdit
    case tapImprovement
    case tapReview
    case tapPrivacyPolicy
    case tapVersionInfo
    case dismissVersionAlert
    case tapTranslationSelection
    case selectPrimaryTranslation(Translation)
    case selectSecondaryTranslation(Translation?)
    case saveTranslations(UserProfile)
    case dismissTranslationSelection
}
