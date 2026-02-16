//
//  UserProfile.swift
//  Domain
//
//  Created by 이승주 on 10/19/25.
//

import Foundation

public struct UserProfile: Equatable {
    public let nickname: String
    public let gender: Gender
    public let profileImageData: Data?
    public let preferredTranslation: Translation
    public let secondaryTranslation: Translation?
    public let fontScale: FontScale
    public let lineSpacing: LineSpacing
    public let isNotificationEnabled: Bool
    public let notificationHour: Int  // 0-23
    public let notificationMinute: Int // 0-59

    public init(
        nickname: String,
        gender: Gender,
        profileImageData: Data? = nil,
        preferredTranslation: Translation = .koreanRevisedVersion,
        secondaryTranslation: Translation? = nil,
        fontScale: FontScale = .medium,
        lineSpacing: LineSpacing = .normal,
        isNotificationEnabled: Bool = true,
        notificationHour: Int = 20,  // 기본값: 오후 8시 30분
        notificationMinute: Int = 30
    ) {
        self.nickname = nickname
        self.gender = gender
        self.profileImageData = profileImageData
        self.preferredTranslation = preferredTranslation
        self.secondaryTranslation = secondaryTranslation
        self.fontScale = fontScale
        self.lineSpacing = lineSpacing
        self.isNotificationEnabled = isNotificationEnabled
        self.notificationHour = notificationHour
        self.notificationMinute = notificationMinute
    }

    public enum Gender: String, Codable {
        case brother = "형제"
        case sister = "자매"
    }
}
