//
//  BibleAPIDataSource.swift
//  Data
//
//  Created by Claude Code on 10/11/25.
//

import Foundation

/// Bible API DTO (bible-api.com 응답)
public struct BibleVerseDTO: Codable {
    public let reference: String    // "John 3:16"
    public let text: String         // 영어 본문
    public let translation_id: String?  // "web" or "kjv"
    public let translation_name: String?

    enum CodingKeys: String, CodingKey {
        case reference
        case text
        case translation_id
        case translation_name
    }
}

/// Bible API DataSource
public final class BibleAPIDataSource {
    private let client: HTTPClient

    public init(client: HTTPClient) {
        self.client = client
    }

    /// 영어 본문 가져오기 (WEB 우선, KJV 폴백)
    public func getVerse(verseRef: String) async throws -> BibleVerseDTO {
        print("📖 [BibleAPI] Fetching: \(verseRef)")

        // 1. WEB 시도
        do {
            let dto = try await fetchVerse(verseRef: verseRef, translation: "web")
            print("✅ [BibleAPI] Success with WEB")
            return dto
        } catch {
            print("⚠️ [BibleAPI] WEB failed, trying KJV...")
        }

        // 2. KJV 폴백
        do {
            let dto = try await fetchVerse(verseRef: verseRef, translation: "kjv")
            print("✅ [BibleAPI] Success with KJV")
            return dto
        } catch {
            print("🔴 [BibleAPI] Both WEB and KJV failed")
            throw error
        }
    }

    private func fetchVerse(verseRef: String, translation: String) async throws -> BibleVerseDTO {
        // URLComponents가 자동으로 인코딩하므로 여기서는 인코딩하지 않음
        let endpoint = Endpoint<EmptyRequest, BibleVerseDTO>(
            path: "/\(verseRef)",
            method: .get,
            queryItems: [URLQueryItem(name: "translation", value: translation)]
        )

        // GET 요청은 body를 nil로 전달
        return try await client.request(endpoint, body: nil, headers: [:])
    }
}
