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
    func setOnboardingCompleted(_ completed: Bool)
    func hasCompletedOnboarding() -> Bool
}

final class DefaultUserDefaultsDataSource: UserDefaultsDataSource {
    private let userDefaults: UserDefaults

    private enum Keys {
        static let nickname = "user_nickname"
        static let gender = "user_gender"
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

    func setOnboardingCompleted(_ completed: Bool) {
        userDefaults.set(completed, forKey: Keys.onboardingCompleted)
    }

    func hasCompletedOnboarding() -> Bool {
        userDefaults.bool(forKey: Keys.onboardingCompleted)
    }
}
