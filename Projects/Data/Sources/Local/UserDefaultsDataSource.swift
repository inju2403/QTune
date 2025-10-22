//
//  UserDefaultsDataSource.swift
//  Data
//
//  Created by 이승주 on 10/19/25.
//

import Foundation

protocol UserDefaultsDataSource {
    func saveNickname(_ nickname: String) throws
    func getNickname() -> String?
    func saveGender(_ gender: String) throws
    func getGender() -> String?
    func saveProfileImage(_ imageData: Data?) throws
    func getProfileImage() -> Data?
    func setOnboardingCompleted(_ completed: Bool)
    func hasCompletedOnboarding() -> Bool
}

final class DefaultUserDefaultsDataSource: UserDefaultsDataSource {
    private let userDefaults: UserDefaults

    private enum Keys {
        static let nickname = "user_nickname"
        static let gender = "user_gender"
        static let profileImage = "user_profile_image"
        static let onboardingCompleted = "onboarding_completed"
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func saveNickname(_ nickname: String) throws {
        userDefaults.set(nickname, forKey: Keys.nickname)
    }

    func getNickname() -> String? {
        userDefaults.string(forKey: Keys.nickname)
    }

    func saveGender(_ gender: String) throws {
        userDefaults.set(gender, forKey: Keys.gender)
    }

    func getGender() -> String? {
        userDefaults.string(forKey: Keys.gender)
    }

    func saveProfileImage(_ imageData: Data?) throws {
        if let imageData = imageData {
            userDefaults.set(imageData, forKey: Keys.profileImage)
        } else {
            userDefaults.removeObject(forKey: Keys.profileImage)
        }
    }

    func getProfileImage() -> Data? {
        userDefaults.data(forKey: Keys.profileImage)
    }

    func setOnboardingCompleted(_ completed: Bool) {
        userDefaults.set(completed, forKey: Keys.onboardingCompleted)
    }

    func hasCompletedOnboarding() -> Bool {
        userDefaults.bool(forKey: Keys.onboardingCompleted)
    }
}
