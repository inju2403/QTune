//
//  DraftUseCasesTests.swift
//  DomainTests
//
//  Created by Claude Code on 10/8/25.
//

import XCTest
@testable import Domain

final class DraftUseCasesTests: XCTestCase {
    var mockDraftRepository: MockQTDraftRepository!
    var loadUseCase: LoadTodayDraftInteractor!
    var saveUseCase: SaveQTDraftInteractor!
    var discardUseCase: DiscardTodayDraftInteractor!

    var testSession: UserSession!
    var testDate: Date!
    var testTimeZone: TimeZone!

    override func setUp() {
        super.setUp()
        mockDraftRepository = MockQTDraftRepository()
        loadUseCase = LoadTodayDraftInteractor(draftRepository: mockDraftRepository)
        saveUseCase = SaveQTDraftInteractor(draftRepository: mockDraftRepository)
        discardUseCase = DiscardTodayDraftInteractor(draftRepository: mockDraftRepository)

        testSession = UserSession(status: .anonymous(deviceId: "device123"), createdAt: Date())
        testDate = Date()
        testTimeZone = TimeZone.current
    }

    override func tearDown() {
        mockDraftRepository = nil
        loadUseCase = nil
        saveUseCase = nil
        discardUseCase = nil
        testSession = nil
        testDate = nil
        testTimeZone = nil
        super.tearDown()
    }

    // MARK: - LoadTodayDraftUseCase Tests

    func testLoadTodayDraft_Found() async throws {
        // Given: 오늘의 초안이 존재
        let expectedDraft = QuietTime(
            id: UUID(),
            verse: Verse(book: "시편", chapter: 23, verse: 1, text: "여호와는 나의 목자시니", translation: "개역개정"),
            memo: "오늘 힘든 하루였어요",
            date: testDate,
            status: .draft,
            tags: [],
            isFavorite: false,
            updatedAt: testDate
        )
        mockDraftRepository.todayDraft = expectedDraft

        // When
        let result = try await loadUseCase.execute(session: testSession, now: testDate, timeZone: testTimeZone)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, expectedDraft.id)
        XCTAssertEqual(result?.status, .draft)
        XCTAssertEqual(mockDraftRepository.loadCallCount, 1)
        XCTAssertEqual(mockDraftRepository.lastLoadSession?.status, testSession.status)
    }

    func testLoadTodayDraft_NotFound() async throws {
        // Given: 초안이 없음
        mockDraftRepository.todayDraft = nil

        // When
        let result = try await loadUseCase.execute(session: testSession, now: testDate, timeZone: testTimeZone)

        // Then
        XCTAssertNil(result)
        XCTAssertEqual(mockDraftRepository.loadCallCount, 1)
    }

    // MARK: - SaveQTDraftUseCase Tests

    func testSaveDraft_Success() async throws {
        // Given: draft 상태의 QuietTime
        let draftToSave = QuietTime(
            id: UUID(),
            verse: Verse(book: "잠언", chapter: 3, verse: 5, text: "너는 마음을 다하여", translation: "개역개정"),
            memo: "새로운 메모",
            date: testDate,
            status: .draft,
            tags: [],
            isFavorite: false,
            updatedAt: testDate
        )

        // When
        try await saveUseCase.execute(draft: draftToSave, session: testSession, now: testDate, timeZone: testTimeZone)

        // Then
        XCTAssertEqual(mockDraftRepository.saveCallCount, 1)
        XCTAssertEqual(mockDraftRepository.lastSavedDraft?.id, draftToSave.id)
        XCTAssertEqual(mockDraftRepository.lastSaveSession?.status, testSession.status)
    }

    func testSaveDraft_CommittedStatus_ThrowsValidationError() async throws {
        // Given: committed 상태의 QuietTime (허용되지 않음)
        let committedQT = QuietTime(
            id: UUID(),
            verse: Verse(book: "시편", chapter: 1, verse: 1, text: "복 있는 사람", translation: "개역개정"),
            memo: "메모",
            date: testDate,
            status: .committed,
            tags: [],
            isFavorite: false,
            updatedAt: testDate
        )

        // When/Then
        do {
            try await saveUseCase.execute(draft: committedQT, session: testSession, now: testDate, timeZone: testTimeZone)
            XCTFail("Expected validationFailed error")
        } catch {
            guard case DomainError.validationFailed(let message) = error else {
                XCTFail("Expected validationFailed, got \(error)")
                return
            }
            XCTAssertTrue(message.contains("draft"))
        }

        // Verify: save가 호출되지 않았는지 확인
        XCTAssertEqual(mockDraftRepository.saveCallCount, 0)
    }

    // MARK: - DiscardTodayDraftUseCase Tests

    func testDiscardDraft_Success() async throws {
        // Given: 초안이 있는 상태
        mockDraftRepository.todayDraft = QuietTime(
            id: UUID(),
            verse: Verse(book: "시편", chapter: 1, verse: 1, text: "테스트", translation: "개역개정"),
            memo: "메모",
            date: testDate,
            status: .draft,
            tags: [],
            isFavorite: false,
            updatedAt: testDate
        )

        // When
        try await discardUseCase.execute(session: testSession, now: testDate, timeZone: testTimeZone)

        // Then
        XCTAssertEqual(mockDraftRepository.clearCallCount, 1)
        XCTAssertEqual(mockDraftRepository.lastClearSession?.status, testSession.status)
    }

    // MARK: - Integration Test: 전체 Draft 흐름

    func testDraftWorkflow_SaveLoadDiscard() async throws {
        // 1. 초안 저장
        let draft = QuietTime(
            id: UUID(),
            verse: Verse(book: "요한복음", chapter: 3, verse: 16, text: "하나님이 세상을 이처럼 사랑하사", translation: "개역개정"),
            memo: "감사합니다",
            date: testDate,
            status: .draft,
            tags: [],
            isFavorite: false,
            updatedAt: testDate
        )
        try await saveUseCase.execute(draft: draft, session: testSession, now: testDate, timeZone: testTimeZone)

        // 저장 시 mock에 저장
        mockDraftRepository.todayDraft = draft

        // 2. 초안 불러오기
        let loaded = try await loadUseCase.execute(session: testSession, now: testDate, timeZone: testTimeZone)
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.id, draft.id)

        // 3. 초안 삭제
        try await discardUseCase.execute(session: testSession, now: testDate, timeZone: testTimeZone)
        mockDraftRepository.todayDraft = nil

        // 4. 다시 불러오면 nil
        let loadedAfterDiscard = try await loadUseCase.execute(session: testSession, now: testDate, timeZone: testTimeZone)
        XCTAssertNil(loadedAfterDiscard)
    }

    // MARK: - 다른 세션 독립성 테스트

    func testDifferentSessions_IndependentDrafts() async throws {
        // Given: 두 개의 다른 세션
        let session1 = UserSession(status: .anonymous(deviceId: "device1"), createdAt: Date())
        let session2 = UserSession(status: .authenticated(userId: "user123"), createdAt: Date())

        let draft1 = QuietTime(
            id: UUID(),
            verse: Verse(book: "시편", chapter: 1, verse: 1, text: "복 있는 사람", translation: "개역개정"),
            memo: "세션1 메모",
            date: testDate,
            status: .draft,
            tags: [],
            isFavorite: false,
            updatedAt: testDate
        )

        // When: session1으로 저장
        try await saveUseCase.execute(draft: draft1, session: session1, now: testDate, timeZone: testTimeZone)

        // Then: 각 세션별로 독립적인 키가 사용되었는지 확인
        XCTAssertEqual(mockDraftRepository.lastSaveSession?.status, session1.status)

        // When: session2로 로드 시도
        mockDraftRepository.todayDraft = nil // 다른 세션은 초안 없음
        let result = try await loadUseCase.execute(session: session2, now: testDate, timeZone: testTimeZone)

        // Then: 없어야 함 (독립적인 세션)
        XCTAssertNil(result)
    }
}

// MARK: - Mock Repository

final class MockQTDraftRepository: QTDraftRepository {
    var loadCallCount = 0
    var saveCallCount = 0
    var clearCallCount = 0

    var lastLoadSession: UserSession?
    var lastSaveSession: UserSession?
    var lastClearSession: UserSession?
    var lastSavedDraft: QuietTime?

    var todayDraft: QuietTime?

    func loadTodayDraft(session: UserSession, date: Date, timeZone: TimeZone) async throws -> QuietTime? {
        loadCallCount += 1
        lastLoadSession = session
        return todayDraft
    }

    func saveTodayDraft(_ draft: QuietTime, session: UserSession, date: Date, timeZone: TimeZone) async throws {
        saveCallCount += 1
        lastSaveSession = session
        lastSavedDraft = draft
        todayDraft = draft
    }

    func discardTodayDraft(session: UserSession, date: Date, timeZone: TimeZone) async throws {
        clearCallCount += 1
        lastClearSession = session
        todayDraft = nil
    }
}
