//
//  FontScale.swift
//  Domain
//
//  Created by 이승주 on 2/6/26.
//

import Foundation

/// 폰트 크기 배율
public enum FontScale: String, Codable, CaseIterable, Equatable {
    case small = "작게"
    case medium = "보통"
    case large = "크게"
    case extraLarge = "아주 크게"

    /// 기본 폰트 크기에 곱할 배율
    public var multiplier: CGFloat {
        switch self {
        case .small: return 0.88      // -12%
        case .medium: return 1.0      // 기본 (100%)
        case .large: return 1.12      // +12%
        case .extraLarge: return 1.24 // +24%
        }
    }

    /// 단계별 표시 텍스트
    public var displayName: String {
        rawValue
    }
}
