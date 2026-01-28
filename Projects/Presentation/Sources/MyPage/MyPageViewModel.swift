//
//  MyPageViewModel.swift
//  Presentation
//
//  Created by 이승주 on 1/15/26.
//

import Foundation
import SwiftUI
import Domain

/// 마이페이지 ViewModel
@Observable
public final class MyPageViewModel {
    // MARK: - State
    public private(set) var state: MyPageState

    // MARK: - Dependencies
    private let saveUserProfileUseCase: SaveUserProfileUseCase

    // MARK: - Callbacks
    public var onProfileEdit: (() -> Void)?
    public var onOpenURL: ((URL) -> Void)?
    public var onTranslationChanged: (() -> Void)?

    // MARK: - Init
    public init(
        initialState: MyPageState = MyPageState(),
        saveUserProfileUseCase: SaveUserProfileUseCase
    ) {
        self.state = initialState
        self.saveUserProfileUseCase = saveUserProfileUseCase
    }

    // MARK: - Send Action
    public func send(_ action: MyPageAction) {
        switch action {
        case .tapProfileEdit:
            onProfileEdit?()

        case .tapImprovement:
            if let url = URL(string: "https://docs.google.com/forms/d/e/1FAIpQLSfzUt_GdAoPGt8ZjGOzsAdtgc6LAK1MPQc2Iu_6izpYB0OlrQ/viewform") {
                onOpenURL?(url)
            }

        case .tapReview:
            if let url = URL(string: "https://apps.apple.com/kr/app/id6757230938?action=write-review") {
                onOpenURL?(url)
            }

        case .tapPrivacyPolicy:
            if let url = URL(string: "https://github.com/inju2403/QTune/blob/dev/privacy-policy.md") {
                onOpenURL?(url)
            }

        case .tapVersionInfo:
            state.showVersionAlert = true

        case .dismissVersionAlert:
            state.showVersionAlert = false

        case .tapTranslationSelection:
            state.showTranslationSelection = true

        case .selectPrimaryTranslation(let translation):
            state.selectedPrimaryTranslation = translation
            // 만약 대조 역본이 기본 역본과 같으면 선택 안 함으로 변경
            if state.selectedSecondaryTranslation == translation {
                state.selectedSecondaryTranslation = nil
            }

        case .selectSecondaryTranslation(let translation):
            state.selectedSecondaryTranslation = translation

        case .saveTranslations(let currentProfile):
            Task { await saveTranslations(currentProfile: currentProfile) }

        case .dismissTranslationSelection:
            state.showTranslationSelection = false
        }
    }

    // MARK: - Actions
    @MainActor
    private func saveTranslations(currentProfile: UserProfile) async {
        let updatedProfile = UserProfile(
            nickname: currentProfile.nickname,
            gender: currentProfile.gender,
            profileImageData: currentProfile.profileImageData,
            preferredTranslation: state.selectedPrimaryTranslation,
            secondaryTranslation: state.selectedSecondaryTranslation
        )

        do {
            try await saveUserProfileUseCase.execute(profile: updatedProfile)
            state.showTranslationSelection = false
            onTranslationChanged?()
        } catch {
            print("❌ Failed to save translation: \(error)")
        }
    }
}
