//
//  AppDependencyContainer.swift
//  App
//
//  Created by 이승주 on 10/11/25.
//

import UIKit
import Foundation
import Domain
import Data
import FirebaseFunctions
import FirebaseAuth

/// 앱 전체 의존성 조립 컨테이너
///
/// Firebase Functions 기반 OpenAI 프록시 사용
/// - OPENAI_API_KEY는 Firebase Functions 환경변수에서만 관리
/// - iOS 앱은 Firebase Functions만 호출
final class AppDependencyContainer {

    // MARK: - Singleton

    static let shared = AppDependencyContainer()

    // MARK: - Properties

    let dummySession: UserSession

    /// QTRepository 인스턴스 (lazy 캐싱)
    private var _qtRepository: QTRepository?

    /// AIRepository 인스턴스 (lazy 캐싱)
    private var _aiRepository: AIRepository?

    /// UserProfileRepository 인스턴스 (lazy 캐싱)
    private var _userProfileRepository: UserProfileRepository?

    // MARK: - Initialization

    private init() {
        print("📦 [AppDependencyContainer] Initializing (Firebase should be configured)")
        // 더미 UserSession 생성 (익명 세션)
        self.dummySession = UserSession.anonymous(deviceId: "local_device")
    }

    // MARK: - Repository Factory

    /// AIRepository 생성 (Firebase Functions 기반, lazy cached)
    func makeAIRepository() -> AIRepository {
        if let cached = _aiRepository {
            return cached
        }

        // Bible API 클라이언트 (그대로 유지)
        let bibleAPIBaseURL = URL(string: "https://bible-api.com")!
        let bibleAPIClient = URLSessionHTTPClient(baseURL: bibleAPIBaseURL)
        let bibleDataSource = BibleAPIDataSource(client: bibleAPIClient)

        // Firebase Functions DataSource (App 레이어에서 직접 생성)
        let firebaseFunctionsDataSource = FirebaseFunctionsAIDataSource()

        let repo = DefaultAIRepository(
            bibleDataSource: bibleDataSource,
            openAIDataSource: firebaseFunctionsDataSource
        )
        _aiRepository = repo
        return repo
    }

    /// RateLimiterRepository 생성
    func makeRateLimiterRepository() -> RateLimiterRepository {
        return UserDefaultsRateLimiterRepository()
    }

    /// UserProfileRepository 생성 (lazy cached)
    func makeUserProfileRepository() -> UserProfileRepository {
        if let cached = _userProfileRepository {
            return cached
        }

        let repo = DefaultUserProfileRepository()
        _userProfileRepository = repo
        return repo
    }

    /// QTRepository 생성 (lazy cached)
    @available(iOS 17, *)
    func makeQTRepository() -> QTRepository? {
        if let cached = _qtRepository {
            return cached
        }

        do {
            let repo = try PersistenceFactory.makeQTRepository()
            _qtRepository = repo
            return repo
        } catch {
            print("❌ Failed to init persistence: \(error)")
            return nil
        }
    }

    // MARK: - UseCase Factory

    /// GenerateVerseUseCase 생성
    func makeGenerateVerseUseCase() -> GenerateVerseUseCase {
        let aiRepository = makeAIRepository()

        return GenerateVerseInteractor(
            aiRepository: aiRepository,
            rateLimiterRepository: makeRateLimiterRepository()
        )
    }

    /// CommitQTUseCase 생성
    @available(iOS 17, *)
    func makeCommitQTUseCase() -> CommitQTUseCase? {
        guard let qtRepository = makeQTRepository() else {
            return nil
        }

        return CommitQTInteractor(qtRepository: qtRepository)
    }

    /// UpdateQTUseCase 생성
    @available(iOS 17, *)
    func makeUpdateQTUseCase() -> UpdateQTUseCase? {
        guard let qtRepository = makeQTRepository() else {
            return nil
        }

        return UpdateQTInteractor(qtRepository: qtRepository)
    }

    /// DeleteQTUseCase 생성
    @available(iOS 17, *)
    func makeDeleteQTUseCase() -> DeleteQTUseCase? {
        guard let qtRepository = makeQTRepository() else {
            return nil
        }

        return DeleteQTInteractor(qtRepository: qtRepository)
    }

    /// FetchQTListUseCase 생성
    @available(iOS 17, *)
    func makeFetchQTListUseCase() -> FetchQTListUseCase? {
        guard let qtRepository = makeQTRepository() else {
            return nil
        }

        return FetchQTListInteractor(qtRepository: qtRepository)
    }

    /// ToggleFavoriteUseCase 생성
    @available(iOS 17, *)
    func makeToggleFavoriteUseCase() -> ToggleFavoriteUseCase? {
        guard let qtRepository = makeQTRepository() else {
            return nil
        }

        return ToggleFavoriteInteractor(qtRepository: qtRepository)
    }

    /// GetQTDetailUseCase 생성
    @available(iOS 17, *)
    func makeGetQTDetailUseCase() -> GetQTDetailUseCase? {
        guard let qtRepository = makeQTRepository() else {
            return nil
        }

        return GetQTDetailInteractor(qtRepository: qtRepository)
    }

    /// SaveUserProfileUseCase 생성
    func makeSaveUserProfileUseCase() -> SaveUserProfileUseCase {
        return DefaultSaveUserProfileUseCase(repository: makeUserProfileRepository())
    }

    /// GetUserProfileUseCase 생성
    func makeGetUserProfileUseCase() -> GetUserProfileUseCase {
        return DefaultGetUserProfileUseCase(repository: makeUserProfileRepository())
    }

    /// UpdateNotificationSettingsUseCase 생성 (Firestore 연동 포함)
    ///
    /// Clean Architecture 원칙:
    /// - Domain UseCase로 UserDefaults 저장
    /// - App 레이어 Wrapper UseCase로 Firestore 저장 추가
    func makeUpdateNotificationSettingsUseCase() -> UpdateNotificationSettingsUseCase {
        let domainUseCase = DefaultUpdateNotificationSettingsUseCase(
            userProfileRepository: makeUserProfileRepository()
        )
        let firestoreRepository = FirestoreNotificationRepository()

        return FirestoreUpdateNotificationSettingsUseCase(
            domainUseCase: domainUseCase,
            firestoreRepository: firestoreRepository
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
        let storageKey = "rateLimiter.\(key).lastUsedDate"

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
