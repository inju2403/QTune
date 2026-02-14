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
    private let updateNotificationSettingsUseCase: UpdateNotificationSettingsUseCase?

    // MARK: - Callbacks
    public var onProfileEdit: (() -> Void)?
    public var onOpenURL: ((URL) -> Void)?
    public var onTranslationChanged: (() -> Void)?
    public var onNotificationChanged: (() -> Void)?

    // MARK: - Init
    public init(
        initialState: MyPageState = MyPageState(),
        saveUserProfileUseCase: SaveUserProfileUseCase,
        updateNotificationSettingsUseCase: UpdateNotificationSettingsUseCase? = nil
    ) {
        self.state = initialState
        self.saveUserProfileUseCase = saveUserProfileUseCase
        self.updateNotificationSettingsUseCase = updateNotificationSettingsUseCase
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
            // 만약 비교 역본이 주 역본과 같으면 선택 안 함으로 변경
            if state.selectedSecondaryTranslation == translation {
                state.selectedSecondaryTranslation = nil
            }

        case .selectSecondaryTranslation(let translation):
            state.selectedSecondaryTranslation = translation

        case .saveTranslations(let currentProfile):
            Task { await saveTranslations(currentProfile: currentProfile) }

        case .dismissTranslationSelection:
            state.showTranslationSelection = false

        case .tapNotificationSettings:
            state.showNotificationSettings = true

        case .toggleNotification(let isEnabled):
            state.isNotificationEnabled = isEnabled

        case .selectNotificationTime(let time):
            state.notificationTime = time

        case .saveNotificationSettings(let currentProfile):
            Task { await saveNotificationSettings(currentProfile: currentProfile) }

        case .dismissNotificationSettings:
            state.showNotificationSettings = false
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

    @MainActor
    private func saveNotificationSettings(currentProfile: UserProfile) async {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: state.notificationTime)
        let hour = components.hour ?? 20
        let minute = components.minute ?? 0

        // Update UserProfile with new notification settings
        let updatedProfile = UserProfile(
            nickname: currentProfile.nickname,
            gender: currentProfile.gender,
            profileImageData: currentProfile.profileImageData,
            preferredTranslation: currentProfile.preferredTranslation,
            secondaryTranslation: currentProfile.secondaryTranslation,
            fontScale: currentProfile.fontScale,
            lineSpacing: currentProfile.lineSpacing,
            isNotificationEnabled: state.isNotificationEnabled,
            notificationHour: hour,
            notificationMinute: minute
        )

        do {
            // Save to UserDefaults
            try await saveUserProfileUseCase.execute(profile: updatedProfile)

            // Save to Firestore if UseCase is available
            if let updateNotificationSettingsUseCase = updateNotificationSettingsUseCase {
                try await updateNotificationSettingsUseCase.execute(
                    isEnabled: state.isNotificationEnabled,
                    hour: hour,
                    minute: minute
                )
            }

            state.showNotificationSettings = false
            onNotificationChanged?()
        } catch {
            print("❌ Failed to save notification settings: \(error)")
        }
    }
}
