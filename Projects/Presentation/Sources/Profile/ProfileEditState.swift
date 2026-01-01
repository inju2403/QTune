//
//  ProfileEditState.swift
//  Presentation
//
//  Created by 이승주 on 10/22/25.
//

import Foundation
import Domain

/// 프로필 편집 화면 State
public struct ProfileEditState: Equatable {
    public var nickname: String
    public var selectedGender: UserProfile.Gender
    public var profileImageData: Data?
    public var isSaving: Bool
    public var showError: Bool

    public init(
        nickname: String = "",
        selectedGender: UserProfile.Gender = .brother,
        profileImageData: Data? = nil,
        isSaving: Bool = false,
        showError: Bool = false
    ) {
        self.nickname = nickname
        self.selectedGender = selectedGender
        self.profileImageData = profileImageData
        self.isSaving = isSaving
        self.showError = showError
    }

    public init(from profile: UserProfile?) {
        self.nickname = profile?.nickname ?? ""
        self.selectedGender = profile?.gender ?? .brother
        self.profileImageData = profile?.profileImageData
        self.isSaving = false
        self.showError = false
    }
}
