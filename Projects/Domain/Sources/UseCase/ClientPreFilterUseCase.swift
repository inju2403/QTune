//
//  ClientPreFilterUseCase.swift
//  Domain
//
//  Created by 이승주 on 10/8/25.
//

import Foundation

/// 클라이언트 1차 필터 유스케이스 (단일 UC)
///
/// ## 목적
/// 서버에 전송하기 전, 클라이언트에서 입력 텍스트를 정규화하고 기본적인 규칙을 검증합니다.
/// - 정규화: 공백, 제로폭 문자, 과도한 반복 제거
/// - 룰 필터: 길이 제한, URL/연락처 감지, 제어문자 제거
/// - UX 피드백: allow/needsReview/block 판정 + 힌트 제공
///
/// ## 설계 원칙
/// - 순수 함수형: 외부 의존성 없음, 상태 변경 없음
/// - 단일 책임: 클라이언트 측 1차 방어만 담당
/// - 서버 신뢰: 최종 보안은 서버 측 Moderation + LLM에서 처리
///
/// ## 처리 단계 (순서 엄수)
/// 1. 공백/제로폭 정규화
/// 2. 길이 제한 (문자 안전 잘라내기)
/// 3. 과도 반복 축약
/// 4. 제어문자/이상치 제거
/// 5. URL/연락처/광고 패턴 감지
/// 6. 언어/문자 집합 휴리스틱
/// 7. 최종 판정 축약
///
/// ## UX 가이드
/// - block: 전송 버튼 비활성 + 에러 메시지
/// - needsReview: 경고 토스트 + 진행 허용
/// - allow: 곧바로 GenerateVerseUseCase로 전달
public struct ClientPreFilterUseCase {

    public init() {}

    /// 입력 텍스트 사전 필터링
    ///
    /// - Parameters:
    ///   - rawText: 사용자가 입력한 원본 텍스트
    ///   - config: 필터링 설정 (기본값: PreFilterConfig.default)
    /// - Returns: PreFilterResult (정규화된 텍스트, 판정, 힌트)
    public func execute(rawText: String, config: PreFilterConfig = .default) -> PreFilterResult {
        var text = rawText
        var codes: [String] = []
        var hints: [Hint] = []

        // MARK: - 1단계: 공백/제로폭 정규화

        /// 선/후행 공백 제거
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)

        /// 중복 공백을 1칸으로 축약
        text = text.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)

        /// 탭 → 스페이스 변환
        text = text.replacingOccurrences(of: "\t", with: " ")

        /// 제로폭 문자 제거 (U+200B, U+FEFF 등)
        let zeroWidthChars = CharacterSet(charactersIn: "\u{200B}\u{200C}\u{200D}\u{FEFF}")
        text = text.components(separatedBy: zeroWidthChars).joined()

        /// 줄바꿈 3+ 연속 → 2로 축약
        text = text.replacingOccurrences(
            of: "(\n|\r\n){3,}",
            with: "\n\n",
            options: .regularExpression
        )

        /// 정규화 후 빈 문자열이면 차단
        if text.isEmpty {
            codes.append("empty_after_normalize")
            return PreFilterResult(
                normalizedText: "",
                verdict: .block(code: "empty_after_normalize"),
                hints: [Hint(messageKey: "error.empty_input")],
                codes: codes
            )
        }

        // MARK: - 2단계: 길이 제한 (문자 안전 잘라내기)

        /// 글자 수 계산 (grapheme cluster 단위)
        let charCount = text.count

        /// 길이 0 → 차단
        if charCount == 0 {
            codes.append("len_zero")
            return PreFilterResult(
                normalizedText: "",
                verdict: .block(code: "len_zero"),
                hints: [Hint(messageKey: "error.empty_input")],
                codes: codes
            )
        }

        /// 최소 길이 미달 → 차단
        if charCount < config.minLen {
            codes.append("len_too_short")
            return PreFilterResult(
                normalizedText: text,
                verdict: .block(code: "len_too_short"),
                hints: [Hint(messageKey: "error.too_short")],
                codes: codes
            )
        }

        /// 최대 길이 초과 → needsReview + 안전하게 자르기
        if charCount > config.maxLen {
            codes.append("len_truncated")
            // 안전한 잘라내기: grapheme cluster 경계 존중
            let index = text.index(text.startIndex, offsetBy: config.maxLen, limitedBy: text.endIndex) ?? text.endIndex
            text = String(text[..<index])
            hints.append(Hint(messageKey: "warning.text_truncated"))
        }

        // MARK: - 3단계: 과도 반복 축약

        /// 동일 문자 >= threshold 연속 → 2개로 축약
        /// 예: "ㅋㅋㅋㅋㅋ" (5개) → "ㅋㅋ" (2개)
        let repeatPattern = #"(.)\1{\#(config.reduceRepeatThreshold - 1),}"#
        let beforeRepeatReduction = text
        text = text.replacingOccurrences(
            of: repeatPattern,
            with: "$1$1",
            options: .regularExpression
        )

        /// 동일 토큰 10회↑ 연속 → 3회로 축약
        /// 예: "하하하하하하하하하하" → "하하하"
        // 간단한 구현: 동일 글자 10개 이상을 3개로
        let tokenRepeatPattern = #"(.{1,3})\1{\#(config.maxSameTokenRepeat - 1),}"#
        text = text.replacingOccurrences(
            of: tokenRepeatPattern,
            with: "$1$1$1",
            options: .regularExpression
        )

        /// 축약만으로 의미가 거의 사라지는 입력 감지
        /// (축약 전 대비 80% 이상 감소하면 의미 없는 반복으로 판단)
        if beforeRepeatReduction.count > 0 && text.count < beforeRepeatReduction.count / 5 {
            codes.append("meaningless_repetition")
            hints.append(Hint(messageKey: "warning.meaningless_repetition"))
        }

        // MARK: - 4단계: 제어문자/이상치 제거

        /// C0 (0x00-0x1F) 및 C1 (0x80-0x9F) 제어문자 제거
        /// 예외: 탭(\t=0x09), 줄바꿈(\n=0x0A), 캐리지리턴(\r=0x0D)
        var controlCharsRemoved = ""
        for scalar in text.unicodeScalars {
            let value = scalar.value
            // C0 제어문자 (탭/줄바꿈/CR 제외)
            if (0x00...0x08).contains(value) ||
                (0x0B...0x0C).contains(value) ||
                (0x0E...0x1F).contains(value) ||
                // C1 제어문자
                (0x80...0x9F).contains(value) {
                continue // 제거
            }
            controlCharsRemoved.append(String(scalar))
        }
        text = controlCharsRemoved

        /// 제어문자 제거 후 비었으면 차단
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            codes.append("only_control_chars")
            return PreFilterResult(
                normalizedText: "",
                verdict: .block(code: "only_control_chars"),
                hints: [Hint(messageKey: "error.invalid_characters")],
                codes: codes
            )
        }

        // MARK: - 5단계: URL/연락처/광고 패턴 감지

        /// URL 패턴 (http(s)://, www., 주요 TLD)
        let urlPatterns = [
            #"https?://[^\s]+"#,
            #"www\.[^\s]+"#,
            #"\b[a-zA-Z0-9.-]+\.(com|net|org|kr|co\.kr|io|app)\b"#
        ]

        /// 전화번호 패턴 (한국 전화번호)
        let phonePatterns = [
            #"01[0-9]-?\d{3,4}-?\d{4}"#,
            #"\b\d{2,4}-\d{3,4}-\d{4}\b"#
        ]

        /// 메신저/연락처 키워드
        let contactKeywords = ["카톡", "카카오", "텔레", "텔레그램", "라인", "line", "kakao", "telegram"]

        /// 광고/홍보 키워드
        let adKeywords = ["할인", "이벤트", "무료", "클릭", "링크", "바로가기"]

        var hasUrl = false
        var hasContact = false

        for pattern in urlPatterns + phonePatterns {
            if let _ = text.range(of: pattern, options: .regularExpression) {
                hasUrl = true
                break
            }
        }

        let lowerText = text.lowercased()
        for keyword in contactKeywords {
            if lowerText.contains(keyword) {
                hasContact = true
                break
            }
        }

        for keyword in adKeywords {
            if lowerText.contains(keyword) {
                // 광고 키워드는 단독으로는 차단하지 않음
                break
            }
        }

        /// URL 또는 연락처 감지 시 needsReview
        if hasUrl || hasContact {
            codes.append("url_or_contact_detected")
            hints.append(Hint(messageKey: "warning.url_or_contact"))
        }

        // MARK: - 6단계: 언어/문자 집합 휴리스틱 (경량화)

        /// 가시 문자 비율 계산
        var visibleCharCount = 0
        var emojiOrSymbolCount = 0

        for scalar in text.unicodeScalars {
            if scalar.properties.isEmoji {
                emojiOrSymbolCount += 1
            } else if CharacterSet.symbols.contains(scalar) || CharacterSet.punctuationCharacters.contains(scalar) {
                emojiOrSymbolCount += 1
            } else if !CharacterSet.whitespacesAndNewlines.contains(scalar) {
                visibleCharCount += 1
            }
        }

        let totalVisibleChars = visibleCharCount + emojiOrSymbolCount

        /// 대다수가 이모지·기호만 → needsReview
        if totalVisibleChars > 0 && Double(emojiOrSymbolCount) / Double(totalVisibleChars) > 0.8 {
            codes.append("gibberish_or_symbols")
            hints.append(Hint(messageKey: "warning.mostly_symbols"))
        }

        /// 한국어/영어 비율 확인 (간단한 휴리스틱)
        var koreanCount = 0
        var englishCount = 0

        for scalar in text.unicodeScalars {
            // 한글 범위: AC00-D7AF (완성형), 1100-11FF (자모)
            if (0xAC00...0xD7AF).contains(scalar.value) || (0x1100...0x11FF).contains(scalar.value) {
                koreanCount += 1
            }
            // 영어 범위: 0041-005A (대문자), 0061-007A (소문자)
            else if (0x0041...0x005A).contains(scalar.value) || (0x0061...0x007A).contains(scalar.value) {
                englishCount += 1
            }
        }

        let alphaCount = koreanCount + englishCount

        /// 한글+영어 비율이 10% 미만이면 지원하지 않는 언어일 가능성
        if totalVisibleChars > 0 && alphaCount > 0 && Double(alphaCount) / Double(totalVisibleChars) < 0.1 {
            codes.append("unsupported_lang_hint")
            hints.append(Hint(messageKey: "warning.unsupported_language"))
        }

        // MARK: - 7단계: 최종 판정 축약

        /// block 사유가 하나라도 있으면 block 우선
        for code in codes {
            if code.hasPrefix("empty_") || code.hasPrefix("len_zero") || code.hasPrefix("len_too_short") || code == "only_control_chars" {
                return PreFilterResult(
                    normalizedText: text,
                    verdict: .block(code: code),
                    hints: hints,
                    codes: codes
                )
            }
        }

        /// needsReview 사유가 하나라도 있으면 needsReview
        if !codes.isEmpty {
            // 첫 번째 코드를 verdict에 사용
            return PreFilterResult(
                normalizedText: text,
                verdict: .needsReview(code: codes.first!),
                hints: hints,
                codes: codes
            )
        }

        /// 그 외는 allow
        return PreFilterResult(
            normalizedText: text,
            verdict: .allow,
            hints: hints,
            codes: codes
        )
    }
}
