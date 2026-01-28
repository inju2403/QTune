//
//  DefaultUserProfileRepository.swift
//  Data
//
//  Created by 이승주 on 10/19/25.
//

import Foundation
import Domain

public final class DefaultUserProfileRepository: UserProfileRepository {
    private let dataSource: UserDefaultsDataSource

    private init(dataSource: UserDefaultsDataSource) {
        self.dataSource = dataSource
    }

    public convenience init() {
        self.init(dataSource: DefaultUserDefaultsDataSource())
    }

    public func saveProfile(_ profile: UserProfile) async throws {
        try dataSource.saveNickname(profile.nickname)
        try dataSource.saveGender(profile.gender.rawValue)
        try dataSource.saveProfileImage(profile.profileImageData)
        try dataSource.savePreferredTranslation(profile.preferredTranslation.code)
        try dataSource.saveSecondaryTranslation(profile.secondaryTranslation?.code)
        dataSource.setOnboardingCompleted(true)
    }

    public func getProfile() async throws -> UserProfile? {
        guard let nickname = dataSource.getNickname(),
              let genderString = dataSource.getGender(),
              let gender = UserProfile.Gender(rawValue: genderString) else {
            return nil
        }

        let profileImageData = dataSource.getProfileImage()
        let translationCode = dataSource.getPreferredTranslation() ?? "KRV"
        let translation = Translation.from(code: translationCode) ?? .koreanRevisedVersion

        let secondaryTranslationCode = dataSource.getSecondaryTranslation()
        let secondaryTranslation = secondaryTranslationCode.flatMap { Translation.from(code: $0) }

        return UserProfile(
            nickname: nickname,
            gender: gender,
            profileImageData: profileImageData,
            preferredTranslation: translation,
            secondaryTranslation: secondaryTranslation
        )
    }

    public func hasCompletedOnboarding() async -> Bool {
        dataSource.hasCompletedOnboarding()
    }
}
