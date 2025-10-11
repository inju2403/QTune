//
//  AuthUseCasesTests.swift
//  DomainTests
//
//  Created by 이승주 on 10/8/25.
//

import XCTest
@testable import Domain

final class AuthUseCasesTests: XCTestCase {
    var mockAuthRepository: MockAuthRepository!
    var mockSyncRepository: MockSyncRepository!
    var getCurrentSessionUseCase: GetCurrentSessionInteractor!
    var signInWithAppleUseCase: SignInWithAppleInteractor!
    var observeAuthStateUseCase: ObserveAuthStateInteractor!

    override func setUp() {
        super.setUp()
        mockAuthRepository = MockAuthRepository()
        mockSyncRepository = MockSyncRepository()
        getCurrentSessionUseCase = GetCurrentSessionInteractor(authRepository: mockAuthRepository)
        signInWithAppleUseCase = SignInWithAppleInteractor(
            authRepository: mockAuthRepository,
            syncRepository: mockSyncRepository
        )
        observeAuthStateUseCase = ObserveAuthStateInteractor(authRepository: mockAuthRepository)
    }

    override func tearDown() {
        mockAuthRepository = nil
        mockSyncRepository = nil
        getCurrentSessionUseCase = nil
        signInWithAppleUseCase = nil
        observeAuthStateUseCase = nil
        super.tearDown()
    }

    // MARK: - GetCurrentSessionUseCase Tests

    func testGetCurrentSession_Anonymous() async throws {
        // Given: 익명 세션
        let anonymousSession = UserSession(status: .anonymous(deviceId: "device123"), createdAt: Date())
        mockAuthRepository.currentSessionValue = anonymousSession

        // When
        let result = try await getCurrentSessionUseCase.execute()

        // Then
        XCTAssertEqual(result.status, .anonymous(deviceId: "device123"))
        XCTAssertEqual(mockAuthRepository.currentSessionCallCount, 1)
    }

    func testGetCurrentSession_Authenticated() async throws {
        // Given: 인증된 세션
        let authenticatedSession = UserSession(status: .authenticated(userId: "user123"), createdAt: Date())
        mockAuthRepository.currentSessionValue = authenticatedSession

        // When
        let result = try await getCurrentSessionUseCase.execute()

        // Then
        XCTAssertEqual(result.status, .authenticated(userId: "user123"))
        XCTAssertEqual(mockAuthRepository.currentSessionCallCount, 1)
    }

    // MARK: - SignInWithAppleUseCase Tests

    func testSignInWithApple_Success() async throws {
        // Given: Apple Sign In 성공
        let authenticatedSession = UserSession(status: .authenticated(userId: "user456"), createdAt: Date())
        mockAuthRepository.signInResult = authenticatedSession
        mockSyncRepository.shouldSucceed = true

        // When
        let result = try await signInWithAppleUseCase.execute(idToken: "test_id_token")

        // Then
        XCTAssertEqual(result.status, .authenticated(userId: "user456"))
        XCTAssertEqual(mockAuthRepository.signInCallCount, 1)
        XCTAssertEqual(mockAuthRepository.lastIdToken, "test_id_token")

        // Verify: 동기화도 수행되었는지 확인
        XCTAssertEqual(mockSyncRepository.mergeCallCount, 1)
        XCTAssertEqual(mockSyncRepository.pullCallCount, 1)

        // Verify: 동기화 순서 확인 (merge → pull)
        XCTAssertTrue(mockSyncRepository.mergeCalledBeforePull)
    }

    func testSignInWithApple_SyncFails_StillReturnsSession() async throws {
        // Given: Apple Sign In은 성공하지만 동기화는 실패
        let authenticatedSession = UserSession(status: .authenticated(userId: "user456"), createdAt: Date())
        mockAuthRepository.signInResult = authenticatedSession
        mockSyncRepository.shouldSucceed = false
        mockSyncRepository.syncError = DomainError.network("Sync failed")

        // When
        let result = try await signInWithAppleUseCase.execute(idToken: "test_id_token")

        // Then: 로그인은 성공으로 처리 (동기화 실패는 무시)
        XCTAssertEqual(result.status, .authenticated(userId: "user456"))
        XCTAssertEqual(mockAuthRepository.signInCallCount, 1)
        XCTAssertEqual(mockSyncRepository.mergeCallCount, 1)

        // 동기화 실패해도 에러를 던지지 않음
    }

    func testSignInWithApple_AuthFails() async throws {
        // Given: Apple Sign In 실패
        mockAuthRepository.shouldThrowError = true
        mockAuthRepository.authError = DomainError.unauthorized

        // When/Then
        do {
            _ = try await signInWithAppleUseCase.execute(idToken: "invalid_token")
            XCTFail("Expected unauthorized error")
        } catch {
            guard case DomainError.unauthorized = error else {
                XCTFail("Expected unauthorized, got \(error)")
                return
            }
        }

        // Verify: 동기화는 시도되지 않았는지 확인
        XCTAssertEqual(mockSyncRepository.mergeCallCount, 0)
        XCTAssertEqual(mockSyncRepository.pullCallCount, 0)
    }

    // MARK: - ObserveAuthStateUseCase Tests

    func testObserveAuthState_EmitsSessionChanges() async throws {
        // Given: 세션 변경 스트림
        let expectation = XCTestExpectation(description: "Receive auth state changes")
        expectation.expectedFulfillmentCount = 2

        let session1 = UserSession(status: .anonymous(deviceId: "device1"), createdAt: Date())
        let session2 = UserSession(status: .authenticated(userId: "user123"), createdAt: Date())

        mockAuthRepository.authStateStream = AsyncStream { continuation in
            continuation.yield(session1)
            continuation.yield(session2)
            continuation.finish()
        }

        // When
        var receivedSessions: [UserSession] = []
        let stream = observeAuthStateUseCase.execute()

        for await session in stream {
            receivedSessions.append(session)
            expectation.fulfill()
        }

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedSessions.count, 2)
        XCTAssertEqual(receivedSessions[0].status, .anonymous(deviceId: "device1"))
        XCTAssertEqual(receivedSessions[1].status, .authenticated(userId: "user123"))
    }

    // MARK: - Integration Test: 전체 인증 흐름

    func testAuthWorkflow_AnonymousToAuthenticated() async throws {
        // 1. 앱 시작 - 익명 세션
        let anonymousSession = UserSession(status: .anonymous(deviceId: "device1"), createdAt: Date())
        mockAuthRepository.currentSessionValue = anonymousSession

        let currentSession = try await getCurrentSessionUseCase.execute()
        XCTAssertEqual(currentSession.status, .anonymous(deviceId: "device1"))

        // 2. Apple Sign In
        let authenticatedSession = UserSession(status: .authenticated(userId: "user123"), createdAt: Date())
        mockAuthRepository.signInResult = authenticatedSession
        mockSyncRepository.shouldSucceed = true

        let signedInSession = try await signInWithAppleUseCase.execute(idToken: "test_token")
        XCTAssertEqual(signedInSession.status, .authenticated(userId: "user123"))

        // 3. 동기화 수행 확인
        XCTAssertEqual(mockSyncRepository.mergeCallCount, 1)
        XCTAssertEqual(mockSyncRepository.pullCallCount, 1)
    }
}

// MARK: - Mock Repositories

final class MockAuthRepository: AuthRepository {
    var currentSessionCallCount = 0
    var signInCallCount = 0
    var lastIdToken: String?

    var currentSessionValue: UserSession?
    var signInResult: UserSession?
    var shouldThrowError = false
    var authError: Error?
    var authStateStream: AsyncStream<UserSession>?

    func currentSession() async throws -> UserSession {
        currentSessionCallCount += 1

        if shouldThrowError, let error = authError {
            throw error
        }

        guard let session = currentSessionValue else {
            throw DomainError.unknown
        }

        return session
    }

    func signInWithApple(idToken: String) async throws -> UserSession {
        signInCallCount += 1
        lastIdToken = idToken

        if shouldThrowError, let error = authError {
            throw error
        }

        guard let session = signInResult else {
            throw DomainError.unauthorized
        }

        return session
    }

    func observeAuthState() -> AsyncStream<UserSession> {
        return authStateStream ?? AsyncStream { continuation in
            continuation.finish()
        }
    }
}

final class MockSyncRepository: SyncRepository {
    var mergeCallCount = 0
    var pullCallCount = 0
    var shouldSucceed = true
    var syncError: Error?

    private var mergeTimestamp: Date?
    private var pullTimestamp: Date?

    var mergeCalledBeforePull: Bool {
        guard let mergeTime = mergeTimestamp, let pullTime = pullTimestamp else {
            return false
        }
        return mergeTime < pullTime
    }

    func mergeLocalIntoRemote(session: UserSession) async throws {
        mergeCallCount += 1
        mergeTimestamp = Date()

        if !shouldSucceed, let error = syncError {
            throw error
        }
    }

    func pullRemoteUpdates(session: UserSession) async throws {
        pullCallCount += 1
        pullTimestamp = Date()

        if !shouldSucceed, let error = syncError {
            throw error
        }
    }
}
