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

    public init(nickname: String, gender: Gender) {
        self.nickname = nickname
        self.gender = gender
    }

    public enum Gender: String, Codable {
        case brother = "형제"
        case sister = "자매"
    }
}
