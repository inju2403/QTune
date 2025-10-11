//
//  OpenAIRemoteDataSource.swift
//  Data
//
//  Created by 이승주 on 10/11/25.
//

import Foundation

/// OpenAI Remote Data Source 에러
public enum OpenAIDataSourceError: Error {
    case emptyResponse
    case invalidJSON
    case apiKeyNotFound
}

/// OpenAI Remote Data Source 프로토콜
public protocol OpenAIRemoteDataSource {
    func generate(_ request: GenerateVerseRequest) async throws -> GeneratedVerseDTO
}

/// OpenAI Remote Data Source 구현
public final class OpenAIDataSource: OpenAIRemoteDataSource {
    private let client: HTTPClient
    private let apiKey: String

    public init(client: HTTPClient, apiKey: String) {
        self.client = client
        self.apiKey = apiKey
    }

    public func generate(_ request: GenerateVerseRequest) async throws -> GeneratedVerseDTO {
        print("🤖 [OpenAIDataSource] Starting verse generation")
        print("   Locale: \(request.locale)")
        print("   Mood: \(request.mood)")
        print("   Note: \(request.note ?? "none")")

        // 1. 프롬프트 생성
        let prompt = buildPrompt(request: request)
        print("📝 [OpenAIDataSource] Prompt generated (length: \(prompt.count))")

        // 2. Payload 생성
        let payload = buildPayload(prompt: prompt)
        print("📦 [OpenAIDataSource] Payload created")

        // 3. API 호출
        let headers = [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json"
        ]

        print("⏳ [OpenAIDataSource] Calling OpenAI API...")
        print("   Authorization: Bearer \(apiKey.prefix(10))...") // API 키 일부만 로깅
        let response: ChatCompletionResponse
        do {
            response = try await client.request(
                OpenAIEndpoint.generateVerse,
                body: payload,
                headers: headers
            )
            print("✅ [OpenAIDataSource] API call successful")
        } catch {
            print("🔴 [OpenAIDataSource] API call failed: \(error)")
            throw error
        }

        // 4. 응답 파싱
        guard let choice = response.choices.first else {
            print("🔴 [OpenAIDataSource] Empty response - no choices")
            throw OpenAIDataSourceError.emptyResponse
        }

        let jsonString = choice.message.content
        print("📄 [OpenAIDataSource] Response content:")
        print("   \(jsonString.prefix(200))...")

        // 5. JSON 디코딩
        guard let jsonData = jsonString.data(using: .utf8) else {
            print("🔴 [OpenAIDataSource] Failed to convert string to data")
            throw OpenAIDataSourceError.invalidJSON
        }

        let decoder = JSONDecoder()
        do {
            let verseDTO = try decoder.decode(GeneratedVerseDTO.self, from: jsonData)
            print("✅ [OpenAIDataSource] Successfully decoded GeneratedVerseDTO")
            print("   verseRef: \(verseDTO.verseRef)")
            print("   safety: \(verseDTO.safety.status)")
            return verseDTO
        } catch {
            print("🔴 [OpenAIDataSource] Decoding failed: \(error)")
            print("   Raw JSON: \(jsonString)")
            throw error
        }
    }

    // MARK: - Private Methods

    private func buildPrompt(request: GenerateVerseRequest) -> String {
        let noteSection = request.note.map { " \($0)" } ?? ""

        // 사용자 locale 확인
        let isKorean = request.locale.hasPrefix("ko")
        let translation = isKorean ? "개역개정 또는 새번역" : "NIV 또는 ESV"

        return """
        큐튠(QTune) 사용자가 "\(request.mood)\(noteSection)"라고 말했어.

        이 사용자에게 딱 맞는 성경 구절 1곳을 추천하고, 왜 이 구절을 추천했는지 2문장 이내로 설명해줘.

        [출력 형식 - 모든 필드 필수]
        - verseRef: "책명 장:절" (예: "시편 23:1")
        - verseText: \(translation) 번역으로 제공
        - verseTextEN: 영어 텍스트 (NIV 또는 ESV) - 항상 제공
        - rationale: 추천 이유 (2문장 이내)
        - tags: 태그 목록 (예: ["위로", "감사", "용기"]) - 최소 1개, 최대 5개
        - safety: 안전성 검증
          * 정상: status="ok", code=0, reason="정상 처리되었습니다"
          * 부적절(욕설/증오/폭력/음란 등): status="blocked", code=1001, reason="사유 요약"

        너무 긴 본문은 피하고 구절 하나만 추천해줘.
        반드시 JSON Schema에 맞춰 모든 필드를 포함하여 응답해줘.
        """
    }

    private func buildPayload(prompt: String) -> ChatCompletionRequest {
        // JSON Schema 정의
        let schema = buildJSONSchema()

        // Chat 메시지 생성
        let message = ChatMessage(
            role: "user",
            content: prompt
        )

        // Response Format 생성
        let responseFormat = ResponseFormat(
            type: "json_schema",
            jsonSchema: schema
        )

        // Payload 생성
        return ChatCompletionRequest(
            model: "gpt-4o-mini",
            messages: [message],
            responseFormat: responseFormat
        )
    }

    private func buildJSONSchema() -> JSONSchema {
        // Safety 스키마 (strict mode에서는 additionalProperties 필수)
        let safetyProperties: [String: PropertyDefinition] = [
            "status": PropertyDefinition(
                type: "string",
                description: "ok 또는 blocked"
            ),
            "code": PropertyDefinition(
                type: "integer",
                description: "0: ok, 1001: blocked"
            ),
            "reason": PropertyDefinition(
                type: "string",
                description: "사유 설명"
            )
        ]

        let safetyDefinition = PropertyDefinition(
            type: "object",
            description: "안전성 검증 결과",
            properties: safetyProperties,
            required: ["status", "code", "reason"],
            additionalProperties: false
        )

        // GeneratedVerseDTO 스키마
        let properties: [String: PropertyDefinition] = [
            "verseRef": PropertyDefinition(
                type: "string",
                description: "성경 구절 참조 (예: 시편 23:1)"
            ),
            "verseText": PropertyDefinition(
                type: "string",
                description: "현지화된 번역본 텍스트"
            ),
            "verseTextEN": PropertyDefinition(
                type: "string",
                description: "영어 텍스트 (선택)"
            ),
            "rationale": PropertyDefinition(
                type: "string",
                description: "추천 이유 (2문장 이내)"
            ),
            "tags": PropertyDefinition(
                type: "array",
                description: "태그 목록 (선택, 최대 5개)",
                items: PropertyDefinition(type: "string"),
                maxItems: 5
            ),
            "safety": safetyDefinition
        ]

        let schemaDefinition = SchemaDefinition(
            type: "object",
            properties: properties,
            required: ["verseRef", "verseText", "verseTextEN", "rationale", "tags", "safety"],
            additionalProperties: false
        )

        return JSONSchema(
            name: "GeneratedVerse",
            strict: true,
            schema: schemaDefinition
        )
    }
}
