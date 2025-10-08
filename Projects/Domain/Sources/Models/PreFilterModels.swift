//
//  PreFilterModels.swift
//  Domain
//
//  Created by Claude Code on 10/8/25.
//

import Foundation

/// 클라이언트 사전 필터링 설정
///
/// ClientPreFilterUseCase의 동작을 제어하는 파라미터들
public struct PreFilterConfig: Equatable {
    /// 최소 글자 수
    public let minLen: Int
    /// 최대 글자 수
    public let maxLen: Int
    /// 동일 문자 반복 축약 임계값 (이 횟수 이상 반복되면 2개로 축약)
    public let reduceRepeatThreshold: Int
    /// 최대 허용 연속 줄바꿈 수
    public let maxNewlines: Int
    /// 동일 토큰 반복 축약 임계값
    public let maxSameTokenRepeat: Int

    public init(
        minLen: Int = 1,
        maxLen: Int = 500,
        reduceRepeatThreshold: Int = 4,
        maxNewlines: Int = 2,
        maxSameTokenRepeat: Int = 10
    ) {
        self.minLen = minLen
        self.maxLen = maxLen
        self.reduceRepeatThreshold = reduceRepeatThreshold
        self.maxNewlines = maxNewlines
        self.maxSameTokenRepeat = maxSameTokenRepeat
    }

    /// 기본 설정
    public static let `default` = PreFilterConfig()
}

/// 사전 필터링 판정 결과
///
/// - allow: 정상 입력, 서버로 전송 가능
/// - needsReview: 경고가 필요하지만 진행 허용
/// - block: 차단, 서버 전송 불가
public enum PreFilterVerdict: Equatable {
    case allow
    case needsReview(code: String)
    case block(code: String)

    /// 서버로 전송 가능 여부
    public var canProceed: Bool {
        switch self {
        case .allow, .needsReview:
            return true
        case .block:
            return false
        }
    }

    /// 판정 코드 (분석/로그용)
    public var code: String? {
        switch self {
        case .allow:
            return nil
        case .needsReview(let code), .block(let code):
            return code
        }
    }
}

/// UI 힌트
///
/// Presentation 레이어에서 사용자에게 표시할 힌트 정보
public struct Hint: Equatable {
    /// 하이라이트할 범위 (선택사항)
    public let range: Range<String.Index>?
    /// 메시지 키 (i18n 대응)
    public let messageKey: String

    public init(range: Range<String.Index>? = nil, messageKey: String) {
        self.range = range
        self.messageKey = messageKey
    }
}

/// 사전 필터링 결과
///
/// ClientPreFilterUseCase의 최종 반환 값
public struct PreFilterResult: Equatable {
    /// 정규화된 텍스트 (서버로 전송할 최종 텍스트)
    public let normalizedText: String
    /// 최종 판정
    public let verdict: PreFilterVerdict
    /// UI 힌트 목록
    public let hints: [Hint]
    /// 발생한 모든 규칙 코드 (분석/로그용)
    public let codes: [String]

    public init(
        normalizedText: String,
        verdict: PreFilterVerdict,
        hints: [Hint] = [],
        codes: [String] = []
    ) {
        self.normalizedText = normalizedText
        self.verdict = verdict
        self.hints = hints
        self.codes = codes
    }

    /// 차단 여부
    public var isBlocked: Bool {
        if case .block = verdict { return true }
        return false
    }

    /// 경고 필요 여부
    public var needsWarning: Bool {
        if case .needsReview = verdict { return true }
        return false
    }
}
