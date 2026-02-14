//
//  UpdateNotificationSettingsUseCase.swift
//  Domain
//
//  Created by 이승주 on 2/14/26.
//

import Foundation

public protocol UpdateNotificationSettingsUseCase {
    func execute(
        isEnabled: Bool,
        hour: Int,
        minute: Int
    ) async throws
}

public final class DefaultUpdateNotificationSettingsUseCase: UpdateNotificationSettingsUseCase {
    private let userProfileRepository: UserProfileRepository

    public init(userProfileRepository: UserProfileRepository) {
        self.userProfileRepository = userProfileRepository
    }

    public func execute(
        isEnabled: Bool,
        hour: Int,
        minute: Int
    ) async throws {
        guard var profile = try await userProfileRepository.getProfile() else {
            throw UpdateNotificationError.profileNotFound
        }

        // 새로운 알림 설정으로 프로필 업데이트
        let updatedProfile = UserProfile(
            nickname: profile.nickname,
            gender: profile.gender,
            profileImageData: profile.profileImageData,
            preferredTranslation: profile.preferredTranslation,
            secondaryTranslation: profile.secondaryTranslation,
            fontScale: profile.fontScale,
            lineSpacing: profile.lineSpacing,
            isNotificationEnabled: isEnabled,
            notificationHour: hour,
            notificationMinute: minute
        )

        try await userProfileRepository.saveProfile(updatedProfile)
    }
}

enum UpdateNotificationError: Error {
    case profileNotFound
}