//
//  Endpoint.swift
//  Data
//
//  Created by 이승주 on 10/11/25.
//

import Foundation

/// HTTP 메서드
public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

/// API 엔드포인트 정의
/// - Req: 요청 바디 타입 (Encodable)
/// - Res: 응답 바디 타입 (Decodable)
public struct Endpoint<Req: Encodable, Res: Decodable> {
    public let path: String
    public let method: HTTPMethod
    public let queryItems: [URLQueryItem]?

    public init(
        path: String,
        method: HTTPMethod,
        queryItems: [URLQueryItem]? = nil
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
    }
}

/// 요청 바디가 없는 엔드포인트를 위한 EmptyRequest
public struct EmptyRequest: Encodable {}

/// 응답 바디가 없는 엔드포인트를 위한 EmptyResponse
public struct EmptyResponse: Decodable {}
