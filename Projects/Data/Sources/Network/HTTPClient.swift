//
//  HTTPClient.swift
//  Data
//
//  Created by 이승주 on 10/11/25.
//

import Foundation

/// HTTP 클라이언트 에러
public enum HTTPClientError: Error {
    case invalidURL
    case invalidResponse
    case statusCode(Int, Data?)
    case encodingFailed(Error)
    case decodingFailed(Error)
    case noData
    case unknown(Error)
}

/// HTTP 클라이언트 프로토콜
public protocol HTTPClient {
    func request<Req: Encodable, Res: Decodable>(
        _ endpoint: Endpoint<Req, Res>,
        body: Req?,
        headers: [String: String]
    ) async throws -> Res
}

/// URLSession 기반 HTTP 클라이언트 구현
public final class URLSessionHTTPClient: HTTPClient {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    public init(
        baseURL: URL,
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
        self.encoder = encoder
    }

    public func request<Req: Encodable, Res: Decodable>(
        _ endpoint: Endpoint<Req, Res>,
        body: Req? = nil,
        headers: [String: String] = [:]
    ) async throws -> Res {
        // URL 생성
        guard var urlComponents = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: true) else {
            print("🔴 [HTTPClient] Invalid URL: \(baseURL.appendingPathComponent(endpoint.path))")
            throw HTTPClientError.invalidURL
        }

        if let queryItems = endpoint.queryItems {
            urlComponents.queryItems = queryItems
        }

        guard let url = urlComponents.url else {
            print("🔴 [HTTPClient] Failed to create URL from components")
            throw HTTPClientError.invalidURL
        }

        // URLRequest 생성
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue

        // 헤더 설정
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // 기본 Content-Type 설정
        if request.value(forHTTPHeaderField: "Content-Type") == nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        print("📡 [HTTPClient] Request:")
        print("   URL: \(url)")
        print("   Method: \(endpoint.method.rawValue)")
        print("   Headers: \(headers)")

        // Body 인코딩
        if let body = body {
            do {
                let encodedData = try encoder.encode(body)
                request.httpBody = encodedData

                if let bodyString = String(data: encodedData, encoding: .utf8) {
                    print("   Body: \(bodyString.prefix(500))...") // 처음 500자만 출력
                }
            } catch {
                print("🔴 [HTTPClient] Encoding failed: \(error)")
                throw HTTPClientError.encodingFailed(error)
            }
        }

        // 요청 실행
        print("⏳ [HTTPClient] Sending request...")
        let (data, response) = try await session.data(for: request)

        // 응답 검증
        guard let httpResponse = response as? HTTPURLResponse else {
            print("🔴 [HTTPClient] Invalid response type")
            throw HTTPClientError.invalidResponse
        }

        print("📥 [HTTPClient] Response:")
        print("   Status Code: \(httpResponse.statusCode)")

        if let responseString = String(data: data, encoding: .utf8) {
            print("   Body: \(responseString.prefix(500))...") // 처음 500자만 출력
        }

        // 상태 코드 검증 (200-299)
        guard (200...299).contains(httpResponse.statusCode) else {
            print("🔴 [HTTPClient] Status code error: \(httpResponse.statusCode)")
            if let errorString = String(data: data, encoding: .utf8) {
                print("   Error body: \(errorString)")
            }
            throw HTTPClientError.statusCode(httpResponse.statusCode, data)
        }

        // 응답 디코딩
        do {
            let decoded = try decoder.decode(Res.self, from: data)
            print("✅ [HTTPClient] Successfully decoded response")
            return decoded
        } catch {
            print("🔴 [HTTPClient] Decoding failed: \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("   Raw response: \(responseString)")
            }
            throw HTTPClientError.decodingFailed(error)
        }
    }
}
