//
//  ModerationRepository.swift
//  Domain
//
//  Created by Claude Code on 10/8/25.
//

import Foundation

/// 콘텐츠 모더레이션 저장소 인터페이스
///
/// 서버 측 전용 모더레이션 모델을 통해 입력 텍스트를 분석합니다.
/// - 도메인은 결과(ModerationReport)만 소비
/// - 실제 모더레이션 로직은 Data 레이어(서버 API)에서 구현
///
/// ## 정책
/// - allowed: 정상 콘텐츠, 진행 허용
/// - needsReview: 의심스러운 콘텐츠이지만 안전 모드로 진행
/// - blocked: 명백한 유해 콘텐츠, 차단
///
/// ## 모더레이션 카테고리 (예시)
/// - violence: 폭력적 표현
/// - sexual: 성적 콘텐츠
/// - hate: 혐오 표현
/// - self-harm: 자해 관련
/// - spam: 스팸/광고
public protocol ModerationRepository {
    /// 텍스트 콘텐츠 분석
    ///
    /// 서버 측 모더레이션 모델로 텍스트를 분석하고 판정 결과를 반환합니다.
    ///
    /// - Parameter text: 분석할 텍스트 (ClientPreFilterUseCase 통과 후의 정규화된 텍스트)
    /// - Returns: ModerationReport (판정 결과, 신뢰도, 감지된 카테고리)
    /// - Throws: DomainError.network (서버 통신 실패)
    func analyze(text: String) async throws -> ModerationReport
}
