//
//  OpenAIEndpoint.swift
//  Data
//
//  Created by 이승주 on 10/11/25.
//

import Foundation

/// OpenAI API 엔드포인트 카탈로그
public enum OpenAIEndpoint {
    /// 구절 생성 엔드포인트 (Chat Completions API with Structured Outputs)
    /// response_format에 json_schema를 포함하여 구조화된 출력을 받음
    public static let generateVerse = Endpoint<ChatCompletionRequest, ChatCompletionResponse>(
        path: "/v1/chat/completions",
        method: .post
    )
}
