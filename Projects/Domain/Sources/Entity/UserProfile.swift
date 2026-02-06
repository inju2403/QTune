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

    public init(
        nickname: String,
        gender: Gender,
        profileImageData: Data? = nil,
        preferredTranslation: Translation = .koreanRevisedVersion,
        secondaryTranslation: Translation? = nil,
        fontScale: FontScale = .medium,
        lineSpacing: LineSpacing = .normal
    ) {
        self.nickname = nickname
        self.gender = gender
        self.profileImageData = profileImageData
        self.preferredTranslation = preferredTranslation
        self.secondaryTranslation = secondaryTranslation
        self.fontScale = fontScale
        self.lineSpacing = lineSpacing
    }

    public enum Gender: String, Codable {
        case brother = "형제"
        case sister = "자매"
    }
}
