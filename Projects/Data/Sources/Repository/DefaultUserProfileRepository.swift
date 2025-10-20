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
        dataSource.setOnboardingCompleted(true)
    }

    public func getProfile() async throws -> UserProfile? {
        guard let nickname = dataSource.getNickname(),
              let genderString = dataSource.getGender(),
              let gender = UserProfile.Gender(rawValue: genderString) else {
            return nil
        }

        return UserProfile(nickname: nickname, gender: gender)
    }

    public func hasCompletedOnboarding() async -> Bool {
        dataSource.hasCompletedOnboarding()
    }
}
