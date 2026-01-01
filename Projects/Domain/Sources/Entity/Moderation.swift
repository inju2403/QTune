//
//  Moderation.swift
//  Domain
//
//  Created by 이승주 on 10/8/25.
//

import Foundation

/// 모더레이션 판정 결과
///
/// 서버 측 ModerationRepository의 분석 결과를 나타냅니다.
/// - allowed: 정상 콘텐츠, 진행 허용
/// - needsReview: 검토 필요하지만 안전 모드로 진행 허용
/// - blocked: 차단, 서비스 이용 불가
public enum ModerationVerdict: Equatable {
    case allowed
    case needsReview(reason: String)
    case blocked(reason: String)

    /// 진행 가능 여부
    public var canProceed: Bool {
        switch self {
        case .allowed, .needsReview:
            return true
        case .blocked:
            return false
        }
    }
}

/// 모더레이션 분석 리포트
///
/// 서버 측 전용 모더레이션 모델의 분석 결과를 담습니다.
/// - verdict: 최종 판정
/// - confidence: 신뢰도 (0.0 ~ 1.0)
/// - categories: 감지된 카테고리들 (예: "violence", "sexual", "hate")
/// - message: 사용자에게 표시할 메시지 (선택)
public struct ModerationReport: Equatable {
    public let verdict: ModerationVerdict
    public let confidence: Double
    public let categories: [String]
    public let message: String?
    public let analyzedAt: Date

    public init(
        verdict: ModerationVerdict,
        confidence: Double,
        categories: [String] = [],
        message: String? = nil,
        analyzedAt: Date = .now
    ) {
        self.verdict = verdict
        self.confidence = confidence
        self.categories = categories
        self.message = message
        self.analyzedAt = analyzedAt
    }
}
