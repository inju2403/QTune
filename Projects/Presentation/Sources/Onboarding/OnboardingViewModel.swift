//
//  OnboardingViewModel.swift
//  Presentation
//
//  Created by 이승주 on 10/19/25.
//

import Foundation
import Domain

/// 온보딩 화면 ViewModel
@Observable
public final class OnboardingViewModel {
    // MARK: - State
    public private(set) var state: OnboardingState

    // MARK: - Dependencies
    private let saveUserProfileUseCase: SaveUserProfileUseCase

    // MARK: - Callbacks
    public var onComplete: (() -> Void)?

    // MARK: - Init
    public init(saveUserProfileUseCase: SaveUserProfileUseCase) {
        self.state = OnboardingState()
        self.saveUserProfileUseCase = saveUserProfileUseCase
    }

    // MARK: - Send Action
    public func send(_ action: OnboardingAction) {
        switch action {
        case .updateNickname(let nickname):
            state.nickname = nickname

        case .selectGender(let gender):
            state.selectedGender = gender

        case .saveProfile:
            Task { await saveProfile() }
        }
    }

    // MARK: - Private Methods
    private func saveProfile() async {
        guard !state.nickname.isEmpty, !state.isSaving else { return }

        state.isSaving = true

        do {
            let profile = UserProfile(
                nickname: state.nickname,
                gender: state.selectedGender,
                profileImageData: nil,
                preferredTranslation: .koreanRevisedVersion  // 새 기기 기본값
            )
            try await saveUserProfileUseCase.execute(profile: profile)

            state.isSaving = false
            onComplete?()
        } catch {
            print("Failed to save profile: \(error)")
            state.isSaving = false
            state.showError = true
        }
    }
}
