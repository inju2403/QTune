//
//  LineSpacing.swift
//  Domain
//
//  Created by 이승주 on 2/6/26.
//

import Foundation

/// 행간 배율
public enum LineSpacing: String, Codable, CaseIterable, Equatable {
    case compact = "좁게"
    case normal = "보통"
    case relaxed = "넓게"
    case extraRelaxed = "아주 넓게"


    /// 폰트 크기에 곱할 행간 배율 (line height)
    public var multiplier: CGFloat {
        switch self {
        case .compact: return 1.0    // 100% (타이트 - 거의 행간 없음)
        case .normal: return 1.235   // 123.5% (원래 앱 기본값)
        case .relaxed: return 1.6    // 160% (넓게 - 명확한 여유)
        case .extraRelaxed: return 2.0 // 200% (아주 넓게)
        }
    }

    /// 단계별 표시 텍스트
    public var displayName: String {
        rawValue
    }
}
