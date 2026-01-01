//
//  ProfileEditViewModel.swift
//  Presentation
//
//  Created by 이승주 on 10/22/25.
//

import Foundation
import Domain

/// 프로필 편집 화면 ViewModel
@Observable
public final class ProfileEditViewModel {
    // MARK: - State
    public private(set) var state: ProfileEditState

    // MARK: - Dependencies
    private let saveUserProfileUseCase: SaveUserProfileUseCase

    // MARK: - Callbacks
    public var onSaveComplete: (() -> Void)?

    // MARK: - Init
    public init(
        currentProfile: UserProfile?,
        saveUserProfileUseCase: SaveUserProfileUseCase
    ) {
        self.state = ProfileEditState(from: currentProfile)
        self.saveUserProfileUseCase = saveUserProfileUseCase
    }

    // MARK: - Send Action
    public func send(_ action: ProfileEditAction) {
        switch action {
        case .updateNickname(let nickname):
            state.nickname = nickname

        case .updateGender(let gender):
            state.selectedGender = gender

        case .updateProfileImage(let imageData):
            state.profileImageData = imageData

        case .saveProfile:
            Task { await saveProfile() }
        }
    }

    // MARK: - Private Methods
    private func saveProfile() async {
        guard !state.isSaving else { return }

        state.isSaving = true

        do {
            let profile = UserProfile(
                nickname: state.nickname,
                gender: state.selectedGender,
                profileImageData: state.profileImageData
            )

            try await saveUserProfileUseCase.execute(profile: profile)

            state.isSaving = false
            onSaveComplete?()
        } catch {
            print("Failed to save profile: \(error)")
            state.isSaving = false
            state.showError = true
        }
    }
}
