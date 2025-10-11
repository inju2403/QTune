//
//  AppDependencyContainer.swift
//  App
//
//  Created by 이승주 on 10/11/25.
//

import Foundation
import Domain
import Data

/// 앱 전체 의존성 조립 컨테이너
///
/// 의존성 주입(DI) 순서:
/// 1. OPENAI_API_KEY 환경변수 읽기
/// 2. HTTP 클라이언트 준비
/// 3. OpenAI RemoteDataSource 생성
/// 4. AIRepository 생성
/// 5. GenerateVerseUseCase 생성
final class AppDependencyContainer {

    // MARK: - Properties

    /// API 키 설정 상태
    enum APIKeyStatus {
        case valid(String)
        case missing
    }

    let apiKeyStatus: APIKeyStatus

    // MARK: - Initialization

    init() {
        // 1. OPENAI_API_KEY 환경변수 읽기
        if let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"],
           !apiKey.isEmpty {
            self.apiKeyStatus = .valid(apiKey)
        } else {
            self.apiKeyStatus = .missing
        }
    }

    // MARK: - Repository Factory

    /// AIRepository 생성
    func makeAIRepository() -> AIRepository? {
        guard case .valid(let apiKey) = apiKeyStatus else {
            return nil
        }

        // 2. HTTP 클라이언트 준비
        let baseURL = URL(string: "https://api.openai.com")!
        let httpClient = URLSessionHTTPClient(baseURL: baseURL)

        // 3. OpenAI RemoteDataSource 생성
        let remoteDataSource = OpenAIDataSource(client: httpClient, apiKey: apiKey)

        // 4. AIRepository 생성
        return DefaultAIRepository(remoteDataSource: remoteDataSource)
    }

    /// RateLimiterRepository 생성
    func makeRateLimiterRepository() -> RateLimiterRepository {
        return UserDefaultsRateLimiterRepository()
    }

    // MARK: - UseCase Factory

    /// 5. GenerateVerseUseCase 생성
    func makeGenerateVerseUseCase() -> GenerateVerseUseCase? {
        guard let aiRepository = makeAIRepository() else {
            return nil
        }

        return GenerateVerseInteractor(
            aiRepository: aiRepository,
            rateLimiterRepository: makeRateLimiterRepository()
        )
    }
}

// MARK: - UserDefaults-based RateLimiter Implementation

final class UserDefaultsRateLimiterRepository: RateLimiterRepository {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func checkAndConsume(key: String, max: Int, per: TimeInterval) async throws -> Bool {
        // TODO: 초당/분당 제한이 필요한 경우 추가 구현
        return true
    }

    func checkDailyLimit(key: String, date: Date, timeZone: TimeZone) async throws -> Bool {
        // 1. 사용자 타임존 기준으로 오늘 날짜 문자열 생성 (yyyy-MM-dd)
        var calendar = Calendar.current
        calendar.timeZone = timeZone

        let dateFormatter = DateFormatter()
        dateFormatter.calendar = calendar
        dateFormatter.timeZone = timeZone
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let todayString = dateFormatter.string(from: date)
        let storageKey = "\(key):lastUsedDate"

        // 2. 저장된 마지막 사용 날짜 가져오기
        let lastUsedDate = userDefaults.string(forKey: storageKey)

        print("🔒 [RateLimiter] Daily limit check")
        print("   Today: \(todayString)")
        print("   Last used: \(lastUsedDate ?? "never")")

        // 3. 오늘 이미 사용했는지 확인
        if lastUsedDate == todayString {
            // 이미 오늘 사용함 -> 제한
            print("   ❌ Already used today - BLOCKED")
            return false
        }

        // 4. 사용 가능 -> 오늘 날짜 저장
        userDefaults.set(todayString, forKey: storageKey)
        print("   ✅ First use today - ALLOWED")
        return true
    }
}
