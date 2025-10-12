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
    func recommendVerse(_ request: GenerateVerseRequest) async throws -> VerseRecommendationDTO
    func generate(_ request: GenerateVerseRequest) async throws -> GeneratedVerseDTO
    func generateKoreanExplanation(englishText: String, verseRef: String, mood: String, note: String?) async throws -> KoreanExplanationDTO
}

/// OpenAI Remote Data Source 구현
public final class OpenAIDataSource: OpenAIRemoteDataSource {
    private let client: HTTPClient
    private let apiKey: String

    public init(client: HTTPClient, apiKey: String) {
        self.client = client
        self.apiKey = apiKey
    }

    public func recommendVerse(_ request: GenerateVerseRequest) async throws -> VerseRecommendationDTO {
        print("🤖 [OpenAIDataSource] Starting verse recommendation")
        print("   Mood: \(request.mood)")
        print("   Note: \(request.note ?? "none")")

        // 1. 프롬프트 생성
        let prompt = buildVerseRecommendationPrompt(request: request)
        print("📝 [OpenAIDataSource] Prompt generated")

        // 2. Payload 생성
        let payload = buildVerseRecommendationPayload(prompt: prompt)
        print("📦 [OpenAIDataSource] Payload created")

        // 3. API 호출
        let headers = [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json"
        ]

        print("⏳ [OpenAIDataSource] Calling OpenAI API for verse recommendation...")
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
            let recommendation = try decoder.decode(VerseRecommendationDTO.self, from: jsonData)
            print("✅ [OpenAIDataSource] Successfully decoded VerseRecommendationDTO")
            print("   verseRef: \(recommendation.verseRef)")
            return recommendation
        } catch {
            print("🔴 [OpenAIDataSource] Decoding failed: \(error)")
            print("   Raw JSON: \(jsonString)")
            throw error
        }
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

    public func generateKoreanExplanation(englishText: String, verseRef: String, mood: String, note: String?) async throws -> KoreanExplanationDTO {
        print("🤖 [OpenAIDataSource] Starting Korean explanation generation")
        print("   VerseRef: \(verseRef)")
        print("   English text length: \(englishText.count)")
        print("   Mood: \(mood)")
        print("   Note: \(note ?? "none")")

        // 1. 프롬프트 생성
        let prompt = buildKoreanExplanationPrompt(englishText: englishText, mood: mood, note: note, verseRef: verseRef)
        print("📝 [OpenAIDataSource] Korean explanation prompt generated")

        // 2. Payload 생성
        let payload = buildKoreanExplanationPayload(prompt: prompt)
        print("📦 [OpenAIDataSource] Payload created")

        // 3. API 호출
        let headers = [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json"
        ]

        print("⏳ [OpenAIDataSource] Calling OpenAI API for Korean explanation...")
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
            let explanationDTO = try decoder.decode(KoreanExplanationDTO.self, from: jsonData)
            print("✅ [OpenAIDataSource] Successfully decoded KoreanExplanationDTO")
            return explanationDTO
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

    // MARK: - Verse Recommendation Private Methods

    private func buildVerseRecommendationPrompt(request: GenerateVerseRequest) -> String {
        let noteSection = request.note.map { " (\($0))" } ?? ""

        return """
        큐튠(QTune) 사용자가 "\(request.mood)\(noteSection)"라고 말했어.

        이 사용자에게 딱 맞는 성경 구절 1곳을 추천하고, 왜 이 구절을 추천했는지 1-2문장으로 설명해줘.

        [출력 형식 - 모든 필드 필수]
        - verseRef: "책명 장:절" 형식 (예: "John 3:16", "Psalms 23:1", "Romans 8:28")
          * 영어 책명 사용 (예: John, Psalms, Romans, Matthew, Genesis 등)
        - rationale: 추천 이유 (1-2문장)

        [규칙]
        - 너무 긴 본문은 피하고 구절 하나만 추천
        - verseRef는 반드시 영어 책명으로 (예: "요한복음" ❌ "John" ✅)
        - 반드시 JSON Schema에 맞춰 모든 필드를 포함하여 응답

        반드시 JSON Schema에 맞춰 응답해줘.
        """
    }

    private func buildVerseRecommendationPayload(prompt: String) -> ChatCompletionRequest {
        let schema = buildVerseRecommendationSchema()

        let message = ChatMessage(
            role: "user",
            content: prompt
        )

        let responseFormat = ResponseFormat(
            type: "json_schema",
            jsonSchema: schema
        )

        return ChatCompletionRequest(
            model: "gpt-4o-mini",
            messages: [message],
            responseFormat: responseFormat
        )
    }

    private func buildVerseRecommendationSchema() -> JSONSchema {
        let properties: [String: PropertyDefinition] = [
            "verseRef": PropertyDefinition(
                type: "string",
                description: "성경 구절 참조 (예: John 3:16, Psalms 23:1)"
            ),
            "rationale": PropertyDefinition(
                type: "string",
                description: "추천 이유 (1-2문장)"
            )
        ]

        let schemaDefinition = SchemaDefinition(
            type: "object",
            properties: properties,
            required: ["verseRef", "rationale"],
            additionalProperties: false
        )

        return JSONSchema(
            name: "VerseRecommendation",
            strict: true,
            schema: schemaDefinition
        )
    }

    // MARK: - Korean Explanation Private Methods

    private func buildKoreanExplanationPrompt(englishText: String, mood: String, note: String?, verseRef: String) -> String {
        let noteSection = note.map { " (\($0))" } ?? ""

        return """
        사용자: "\(mood)\(noteSection)"

        성경 구절: \(verseRef)
        영어 본문:
        \(englishText)

        [출력 형식]
        - korean: "{한글 성경 구절명}\n{자연스럽고 은혜로운 의역문}"
        - rationale: 추천 이유 (1-2문장, 한국어)

        [규칙 - 매우 중요]
        1. **korean 형식**: 한글 구절명 + 개행(\n) + 의역문
           - 예: "빌립보서 4:13\n그리스도께서 저에게 힘을 주시기에, 저는 모든 것을 해낼 수 있습니다."
           - 구절명 뒤에 마침표(.) 붙이지 말 것!
           - 한글 책명: John → 요한복음, Philippians → 빌립보서, Psalms → 시편, 1 John → 요한일서

        2. **문장 구조 (자연스러운 의역)**:
           - 1~2문장으로 구성
           - 자연스러운 한국어 어순으로 의역
           - 직역 금지, 의미 중심으로 재구성
           - 개역개정/개역한글과 문장 구조 70% 이상 유사하면 안 됨

        3. **어휘 (자연스러운 현대어)**:
           - 고어체 금지: "~하사", "~하심이라", "멸망치 않고" 등
           - 자연스러운 표현: "~하셔서", "~하시려는 것입니다", "멸망하지 않고"
           - 종결형: "~입니다", "~하십니다" 사용

        4. **감정톤**:
           - 따뜻하고 위로적인 어조
           - 설교체 금지, 시적 과장 금지
           - 묵상에 적합한 명료한 문체

        5. **길이**: 영문 본문의 80~130% 범위

        6. **절대 금지**:
           - 개역개정 문장 구조 모방
           - "오늘 당신은...", "~위로하십니다" 등 설교체
           - 영어 단어 삽입

        [예시 - 개역개정과 다르게]
        ❌ 잘못: "하나님이 세상을 이처럼 사랑하사 독생자를 주셨으니, 이를 믿는 자마다 멸망치 않고 영생을 얻게 하려 하심이라."
        ✅ 올바름: "하나님은 세상을 깊이 사랑하셔서, 자신의 외아들을 우리에게 보내셨습니다. 그를 믿는 사람은 멸망하지 않고, 영원한 생명을 누리게 하셨습니다."

        ❌ 잘못: "이는 화와 악이 아닌 평화를 위해서이며, 희망과 미래를 주기 위함이다."
        ✅ 올바름: "주님은 당신을 향한 계획을 알고 계시며, 그것은 재앙이 아니라 평화와 소망으로 가득한 미래를 주시려는 것입니다."

        입력: Philippians 4:13 / "I can do all things through Christ who strengthens me."
        korean: "빌립보서 4:13\n그리스도께서 저에게 힘을 주시기에, 저는 모든 것을 해낼 수 있습니다."
        rationale: "어려운 상황에서도 그리스도의 능력으로 극복할 수 있다는 확신을 줍니다."

        반드시 JSON Schema에 맞춰 응답.
        """
    }

    private func buildKoreanExplanationPayload(prompt: String) -> ChatCompletionRequest {
        // JSON Schema 정의
        let schema = buildKoreanExplanationSchema()

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

    private func buildKoreanExplanationSchema() -> JSONSchema {
        // KoreanExplanationDTO 스키마
        let properties: [String: PropertyDefinition] = [
            "korean": PropertyDefinition(
                type: "string",
                description: "한국어 해석 (영문 길이의 80~130%, 의역)"
            ),
            "rationale": PropertyDefinition(
                type: "string",
                description: "추천 이유 (1-2문장)"
            )
        ]

        let schemaDefinition = SchemaDefinition(
            type: "object",
            properties: properties,
            required: ["korean", "rationale"],
            additionalProperties: false
        )

        return JSONSchema(
            name: "KoreanExplanation",
            strict: true,
            schema: schemaDefinition
        )
    }
}
