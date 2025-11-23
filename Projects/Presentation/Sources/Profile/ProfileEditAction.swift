//
//  ProfileEditAction.swift
//  Presentation
//
//  Created by 이승주 on 10/22/25.
//

import Foundation
import Domain

/// 프로필 편집 화면 Action
public enum ProfileEditAction: Equatable {
    case updateNickname(String)
    case updateGender(UserProfile.Gender)
    case updateProfileImage(Data?)
    case saveProfile
}
