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
    func savePreferredTranslation(_ translationCode: String) throws
    func getPreferredTranslation() -> String?
    func saveSecondaryTranslation(_ translationCode: String?) throws
    func getSecondaryTranslation() -> String?
    func saveFontScale(_ fontScale: String) throws
    func getFontScale() -> String?
    func saveLineSpacing(_ lineSpacing: String) throws
    func getLineSpacing() -> String?
    func setOnboardingCompleted(_ completed: Bool)
    func hasCompletedOnboarding() -> Bool
    func saveNotificationEnabled(_ enabled: Bool) throws
    func isNotificationEnabled() -> Bool
    func saveNotificationTime(hour: Int, minute: Int) throws
    func getNotificationTime() -> (hour: Int, minute: Int)
}

final class DefaultUserDefaultsDataSource: UserDefaultsDataSource {
    private let userDefaults: UserDefaults

    private enum Keys {
        static let nickname = "user_nickname"
        static let gender = "user_gender"
        static let profileImage = "user_profile_image"
        static let preferredTranslation = "user_preferred_translation"
        static let secondaryTranslation = "user_secondary_translation"
        static let fontScale = "user_font_scale"
        static let lineSpacing = "user_line_spacing"
        static let onboardingCompleted = "onboarding_completed"
        static let notificationEnabled = "notification_enabled"
        static let notificationHour = "notification_hour"
        static let notificationMinute = "notification_minute"
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

    func savePreferredTranslation(_ translationCode: String) throws {
        userDefaults.set(translationCode, forKey: Keys.preferredTranslation)
    }

    func getPreferredTranslation() -> String? {
        // 기본값: 개역한글(KRV)
        userDefaults.string(forKey: Keys.preferredTranslation) ?? "KRV"
    }

    func saveSecondaryTranslation(_ translationCode: String?) throws {
        if let translationCode = translationCode {
            userDefaults.set(translationCode, forKey: Keys.secondaryTranslation)
        } else {
            userDefaults.removeObject(forKey: Keys.secondaryTranslation)
        }
    }

    func getSecondaryTranslation() -> String? {
        // 기본값: nil (선택 안 함)
        userDefaults.string(forKey: Keys.secondaryTranslation)
    }

    func saveFontScale(_ fontScale: String) throws {
        userDefaults.set(fontScale, forKey: Keys.fontScale)
    }

    func getFontScale() -> String? {
        // 기본값: medium
        userDefaults.string(forKey: Keys.fontScale) ?? "보통"
    }

    func saveLineSpacing(_ lineSpacing: String) throws {
        userDefaults.set(lineSpacing, forKey: Keys.lineSpacing)
    }

    func getLineSpacing() -> String? {
        // 기본값: normal
        userDefaults.string(forKey: Keys.lineSpacing) ?? "보통"
    }

    func setOnboardingCompleted(_ completed: Bool) {
        userDefaults.set(completed, forKey: Keys.onboardingCompleted)
    }

    func hasCompletedOnboarding() -> Bool {
        userDefaults.bool(forKey: Keys.onboardingCompleted)
    }

    func saveNotificationEnabled(_ enabled: Bool) throws {
        userDefaults.set(enabled, forKey: Keys.notificationEnabled)
    }

    func isNotificationEnabled() -> Bool {
        // 기본값: true (활성화)
        if userDefaults.object(forKey: Keys.notificationEnabled) == nil {
            return true
        }
        return userDefaults.bool(forKey: Keys.notificationEnabled)
    }

    func saveNotificationTime(hour: Int, minute: Int) throws {
        userDefaults.set(hour, forKey: Keys.notificationHour)
        userDefaults.set(minute, forKey: Keys.notificationMinute)
    }

    func getNotificationTime() -> (hour: Int, minute: Int) {
        // 기본값: 오후 8시 30분 (20:30)
        let hour = userDefaults.object(forKey: Keys.notificationHour) as? Int ?? 20
        let minute = userDefaults.object(forKey: Keys.notificationMinute) as? Int ?? 30
        return (hour, minute)
    }
}
