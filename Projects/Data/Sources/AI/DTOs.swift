//
//  DTOs.swift
//  Data
//
//  Created by 이승주 on 10/11/25.
//

import Foundation

// MARK: - Bible API Response DTOs

/// Bible API 응답은 BibleAPIDataSource.swift에 정의됨

// MARK: - OpenAI Verse Recommendation DTOs

/// GPT 구절 추천 DTO
public struct VerseRecommendationDTO: Codable {
    public let verseRef: String     // 예: "John 3:16", "Psalms 23:1"
    public let rationale: String    // 추천 이유 (1-2문장)

    public init(verseRef: String, rationale: String) {
        self.verseRef = verseRef
        self.rationale = rationale
    }
}

// MARK: - OpenAI Korean Explanation DTOs

/// GPT 한글 해설 DTO
public struct KoreanExplanationDTO: Codable {
    public let korean: String       // 한글 해석 (영문 길이의 80~130%)
    public let rationale: String    // 추천 이유 (1-2문장)

    public init(korean: String, rationale: String) {
        self.korean = korean
        self.rationale = rationale
    }
}

// MARK: - Legacy Response DTOs (OpenAI가 반환하는 구조화된 JSON)

/// 생성된 성경 구절 DTO
public struct GeneratedVerseDTO: Codable {
    public let verseRef: String       // 예: "시편 23:1"
    public let verseText: String      // 현지화된 번역본 텍스트
    public let verseTextEN: String?   // 영어 텍스트 (선택)
    public let rationale: String      // 추천 이유 (2문장 이내)
    public let tags: [String]?        // 태그 (선택)
    public let safety: Safety         // 안전성 정보

    public init(
        verseRef: String,
        verseText: String,
        verseTextEN: String?,
        rationale: String,
        tags: [String]?,
        safety: Safety
    ) {
        self.verseRef = verseRef
        self.verseText = verseText
        self.verseTextEN = verseTextEN
        self.rationale = rationale
        self.tags = tags
        self.safety = safety
    }
}

/// 안전성 검증 결과
public struct Safety: Codable {
    public let status: String   // "ok" | "blocked"
    public let code: Int        // 0: ok, 1001: blocked
    public let reason: String   // 사유 설명

    public init(status: String, code: Int, reason: String) {
        self.status = status
        self.code = code
        self.reason = reason
    }
}

// MARK: - OpenAI Chat Completions API Response

/// OpenAI Chat Completions API 응답 구조
public struct ChatCompletionResponse: Codable {
    public let id: String
    public let object: String
    public let created: Int
    public let model: String
    public let choices: [Choice]

    public struct Choice: Codable {
        public let index: Int
        public let message: Message
        public let finishReason: String?

        enum CodingKeys: String, CodingKey {
            case index
            case message
            case finishReason = "finish_reason"
        }
    }

    public struct Message: Codable {
        public let role: String
        public let content: String
    }
}

// MARK: - Request Payloads

/// OpenAI Chat Completions API 요청 페이로드
public struct ChatCompletionRequest: Encodable {
    public let model: String
    public let messages: [ChatMessage]
    public let responseFormat: ResponseFormat

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case responseFormat = "response_format"
    }

    public init(model: String, messages: [ChatMessage], responseFormat: ResponseFormat) {
        self.model = model
        self.messages = messages
        self.responseFormat = responseFormat
    }
}

/// Chat 메시지
public struct ChatMessage: Encodable {
    public let role: String
    public let content: String

    public init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}

/// 응답 포맷 (JSON Schema)
public struct ResponseFormat: Encodable {
    public let type: String
    public let jsonSchema: JSONSchema

    enum CodingKeys: String, CodingKey {
        case type
        case jsonSchema = "json_schema"
    }

    public init(type: String, jsonSchema: JSONSchema) {
        self.type = type
        self.jsonSchema = jsonSchema
    }
}

/// JSON Schema 정의
public struct JSONSchema: Encodable {
    public let name: String
    public let strict: Bool
    public let schema: SchemaDefinition

    public init(name: String, strict: Bool, schema: SchemaDefinition) {
        self.name = name
        self.strict = strict
        self.schema = schema
    }
}

/// Schema 정의
public struct SchemaDefinition: Encodable {
    public let type: String
    public let properties: [String: PropertyDefinition]
    public let required: [String]
    public let additionalProperties: Bool

    enum CodingKeys: String, CodingKey {
        case type
        case properties
        case required
        case additionalProperties = "additionalProperties"
    }

    public init(
        type: String,
        properties: [String: PropertyDefinition],
        required: [String],
        additionalProperties: Bool
    ) {
        self.type = type
        self.properties = properties
        self.required = required
        self.additionalProperties = additionalProperties
    }
}

/// Property 정의 (재귀 구조를 위한 Box)
private final class Box<T: Encodable>: Encodable {
    let value: T
    init(_ value: T) { self.value = value }
    func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}

/// Property 정의
public struct PropertyDefinition: Encodable {
    public let type: String?
    public let description: String?
    private let itemsBox: Box<PropertyDefinition>?
    public let properties: [String: PropertyDefinition]?
    public let required: [String]?
    public let additionalProperties: Bool?
    public let maxItems: Int?

    public var items: PropertyDefinition? {
        itemsBox?.value
    }

    enum CodingKeys: String, CodingKey {
        case type
        case description
        case items
        case properties
        case required
        case additionalProperties
        case maxItems
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(itemsBox?.value, forKey: .items)
        try container.encodeIfPresent(properties, forKey: .properties)
        try container.encodeIfPresent(required, forKey: .required)
        try container.encodeIfPresent(additionalProperties, forKey: .additionalProperties)
        try container.encodeIfPresent(maxItems, forKey: .maxItems)
    }

    public init(
        type: String?,
        description: String? = nil,
        items: PropertyDefinition? = nil,
        properties: [String: PropertyDefinition]? = nil,
        required: [String]? = nil,
        additionalProperties: Bool? = nil,
        maxItems: Int? = nil
    ) {
        self.type = type
        self.description = description
        self.itemsBox = items.map(Box.init)
        self.properties = properties
        self.required = required
        self.additionalProperties = additionalProperties
        self.maxItems = maxItems
    }
}

// MARK: - Request Models

/// 구절 생성 요청
public struct GenerateVerseRequest {
    public let locale: String       // 예: "ko_KR", "en_US"
    public let mood: String         // 사용자의 감정/상황
    public let note: String?        // 추가 메모
    public let nickname: String?    // 사용자 닉네임
    public let gender: String?      // 사용자 성별

    public init(locale: String, mood: String, note: String?, nickname: String? = nil, gender: String? = nil) {
        self.locale = locale
        self.mood = mood
        self.note = note
        self.nickname = nickname
        self.gender = gender
    }
}
