//
//  GenerateVerseUseCase.swift
//  Domain
//
//  Created by 이승주 on 7/26/25.
//

import Foundation

/// 말씀 생성 유스케이스
///
/// ClientPreFilterUseCase로 정규화된 텍스트를 받아서
/// Rate Limiting + Moderation + LLM 생성을 수행합니다.
public protocol GenerateVerseUseCase {
    /// 말씀 생성 실행
    ///
    /// - Parameters:
    ///   - normalizedText: ClientPreFilterUseCase에서 정규화된 텍스트
    ///   - userId: 사용자 ID (rate limiting용)
    /// - Returns: 생성된 말씀
    func execute(normalizedText: String, userId: String) async throws -> GeneratedVerse
}
