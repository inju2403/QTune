//
//  Translation.swift
//  Domain
//
//  Created by 이승주 on 1/25/26.
//

import Foundation

/// 성경 역본 (번역본)
public enum Translation: String, Equatable, Hashable, CaseIterable {
    case koreanRevisedVersion = "개역한글"
    case worldEnglishBible = "WEB"
    case kingJamesVersion = "KJV"

    /// 표시용 이름
    public var displayName: String {
        return rawValue
    }

    /// API/Firestore 저장용 코드
    public var code: String {
        switch self {
        case .koreanRevisedVersion:
            return "KRV"
        case .worldEnglishBible:
            return "WEB"
        case .kingJamesVersion:
            return "KJV"
        }
    }

    /// 언어
    public var language: String {
        switch self {
        case .koreanRevisedVersion:
            return "ko"
        case .worldEnglishBible, .kingJamesVersion:
            return "en"
        }
    }

    /// code로부터 Translation 생성
    public static func from(code: String) -> Translation? {
        return Translation.allCases.first { $0.code == code }
    }
}
