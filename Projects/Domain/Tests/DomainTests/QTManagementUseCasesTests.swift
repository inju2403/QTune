//
//  QTManagementUseCasesTests.swift
//  DomainTests
//
//  Created by Claude Code on 10/8/25.
//

import XCTest
@testable import Domain

final class QTManagementUseCasesTests: XCTestCase {
    var mockQTRepository: MockQTRepository!
    var commitUseCase: CommitQTInteractor!
    var fetchListUseCase: FetchQTListInteractor!
    var getDetailUseCase: GetQTDetailInteractor!
    var toggleFavoriteUseCase: ToggleFavoriteInteractor!

    var testSession: UserSession!

    override func setUp() {
        super.setUp()
        mockQTRepository = MockQTRepository()
        commitUseCase = CommitQTInteractor(qtRepository: mockQTRepository)
        fetchListUseCase = FetchQTListInteractor(qtRepository: mockQTRepository)
        getDetailUseCase = GetQTDetailInteractor(qtRepository: mockQTRepository)
        toggleFavoriteUseCase = ToggleFavoriteInteractor(qtRepository: mockQTRepository)

        testSession = UserSession(status: .authenticated(userId: "user123"), createdAt: Date())
    }

    override func tearDown() {
        mockQTRepository = nil
        commitUseCase = nil
        fetchListUseCase = nil
        getDetailUseCase = nil
        toggleFavoriteUseCase = nil
        testSession = nil
        super.tearDown()
    }

    // MARK: - CommitQTUseCase Tests

    func testCommitQT_Success() async throws {
        // Given: draft 상태의 QuietTime
        let draft = QuietTime(
            id: UUID(),
            verse: Verse(book: "시편", chapter: 23, verse: 1, text: "여호와는 나의 목자시니", translation: "개역개정"),
            memo: "오늘의 묵상",
            date: Date(),
            status: .draft,
            tags: [],
            isFavorite: false,
            updatedAt: Date()
        )

        let committedQT = QuietTime(
            id: draft.id,
            verse: draft.verse,
            memo: draft.memo,
            date: draft.date,
            status: .committed,
            tags: draft.tags,
            isFavorite: draft.isFavorite,
            updatedAt: Date()
        )
        mockQTRepository.committedQT = committedQT

        // When
        let result = try await commitUseCase.execute(draft: draft, session: testSession)

        // Then
        XCTAssertEqual(result.status, .committed)
        XCTAssertEqual(result.id, draft.id)
        XCTAssertEqual(mockQTRepository.commitCallCount, 1)
        XCTAssertEqual(mockQTRepository.lastCommittedDraft?.id, draft.id)
    }

    func testCommitQT_AlreadyCommitted_ThrowsValidationError() async throws {
        // Given: 이미 committed 상태 (허용되지 않음)
        let alreadyCommitted = QuietTime(
            id: UUID(),
            verse: Verse(book: "시편", chapter: 1, verse: 1, text: "복 있는 사람", translation: "개역개정"),
            memo: "메모",
            date: Date(),
            status: .committed,
            tags: [],
            isFavorite: false,
            updatedAt: Date()
        )

        // When/Then
        do {
            _ = try await commitUseCase.execute(draft: alreadyCommitted, session: testSession)
            XCTFail("Expected validationFailed error")
        } catch {
            guard case DomainError.validationFailed(let message) = error else {
                XCTFail("Expected validationFailed, got \(error)")
                return
            }
            XCTAssertTrue(message.contains("draft"))
        }

        XCTAssertEqual(mockQTRepository.commitCallCount, 0)
    }

    // MARK: - FetchQTListUseCase Tests

    func testFetchQTList_AllQTs() async throws {
        // Given: 여러 개의 QT
        let qt1 = createCommittedQT(memo: "QT 1", isFavorite: false)
        let qt2 = createCommittedQT(memo: "QT 2", isFavorite: true)
        let qt3 = createCommittedQT(memo: "QT 3", isFavorite: false)
        mockQTRepository.qtList = [qt1, qt2, qt3]

        // When: 전체 조회
        let result = try await fetchListUseCase.execute(query: QTQuery(), session: testSession)

        // Then
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(mockQTRepository.fetchListCallCount, 1)
    }

    func testFetchQTList_FavoritesOnly() async throws {
        // Given: 즐겨찾기 2개 포함
        let qt1 = createCommittedQT(memo: "QT 1", isFavorite: false)
        let qt2 = createCommittedQT(memo: "QT 2", isFavorite: true)
        let qt3 = createCommittedQT(memo: "QT 3", isFavorite: true)
        mockQTRepository.qtList = [qt2, qt3] // 즐겨찾기만 반환

        // When: 즐겨찾기 필터
        let result = try await fetchListUseCase.execute(query: .favoritesOnly(), session: testSession)

        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.isFavorite })
        XCTAssertEqual(mockQTRepository.lastQuery?.isFavorite, true)
    }

    func testFetchQTList_DateRange() async throws {
        // Given: 특정 날짜 범위의 QT
        let startDate = Date()
        let endDate = Date().addingTimeInterval(7 * 24 * 3600) // 7일 후
        let dateRange = DateRange(start: startDate, end: endDate)

        let qt1 = createCommittedQT(memo: "이번 주 QT", isFavorite: false)
        mockQTRepository.qtList = [qt1]

        // When
        let result = try await fetchListUseCase.execute(
            query: QTQuery(dateRange: dateRange),
            session: testSession
        )

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(mockQTRepository.lastQuery?.dateRange?.start, startDate)
        XCTAssertEqual(mockQTRepository.lastQuery?.dateRange?.end, endDate)
    }

    // MARK: - GetQTDetailUseCase Tests

    func testGetQTDetail_Found() async throws {
        // Given: 존재하는 QT
        let qt = createCommittedQT(memo: "상세 QT", isFavorite: false)
        mockQTRepository.qtDetail = qt

        // When
        let result = try await getDetailUseCase.execute(id: qt.id, session: testSession)

        // Then
        XCTAssertEqual(result.id, qt.id)
        XCTAssertEqual(result.memo, "상세 QT")
        XCTAssertEqual(mockQTRepository.getCallCount, 1)
        XCTAssertEqual(mockQTRepository.lastGetId, qt.id)
    }

    func testGetQTDetail_NotFound() async throws {
        // Given: 존재하지 않는 QT
        mockQTRepository.shouldThrowNotFound = true

        // When/Then
        do {
            _ = try await getDetailUseCase.execute(id: UUID(), session: testSession)
            XCTFail("Expected notFound error")
        } catch {
            guard case DomainError.notFound = error else {
                XCTFail("Expected notFound, got \(error)")
                return
            }
        }
    }

    // MARK: - ToggleFavoriteUseCase Tests

    func testToggleFavorite_FalseToTrue() async throws {
        // Given: 즐겨찾기 아닌 QT
        let qt = createCommittedQT(memo: "QT", isFavorite: false)
        mockQTRepository.newFavoriteState = true

        // When
        let result = try await toggleFavoriteUseCase.execute(id: qt.id, session: testSession)

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(mockQTRepository.toggleFavoriteCallCount, 1)
        XCTAssertEqual(mockQTRepository.lastToggleFavoriteId, qt.id)
    }

    func testToggleFavorite_TrueToFalse() async throws {
        // Given: 즐겨찾기인 QT
        let qt = createCommittedQT(memo: "QT", isFavorite: true)
        mockQTRepository.newFavoriteState = false

        // When
        let result = try await toggleFavoriteUseCase.execute(id: qt.id, session: testSession)

        // Then
        XCTAssertFalse(result)
        XCTAssertEqual(mockQTRepository.toggleFavoriteCallCount, 1)
    }

    // MARK: - Integration Test: 전체 QT 관리 흐름

    func testQTManagementWorkflow() async throws {
        // 1. Draft 커밋
        let draft = QuietTime(
            id: UUID(),
            verse: Verse(book: "요한복음", chapter: 3, verse: 16, text: "하나님이 세상을", translation: "개역개정"),
            memo: "감사",
            date: Date(),
            status: .draft,
            tags: [],
            isFavorite: false,
            updatedAt: Date()
        )
        let committed = QuietTime(
            id: draft.id,
            verse: draft.verse,
            memo: draft.memo,
            date: draft.date,
            status: .committed,
            tags: draft.tags,
            isFavorite: false,
            updatedAt: Date()
        )
        mockQTRepository.committedQT = committed

        let result1 = try await commitUseCase.execute(draft: draft, session: testSession)
        XCTAssertEqual(result1.status, .committed)

        // 2. 목록 조회
        mockQTRepository.qtList = [committed]
        let list = try await fetchListUseCase.execute(query: QTQuery(), session: testSession)
        XCTAssertEqual(list.count, 1)

        // 3. 상세 조회
        mockQTRepository.qtDetail = committed
        let detail = try await getDetailUseCase.execute(id: committed.id, session: testSession)
        XCTAssertEqual(detail.id, committed.id)

        // 4. 즐겨찾기 토글
        mockQTRepository.newFavoriteState = true
        let favoriteState = try await toggleFavoriteUseCase.execute(id: committed.id, session: testSession)
        XCTAssertTrue(favoriteState)
    }

    // MARK: - Helper Methods

    private func createCommittedQT(memo: String, isFavorite: Bool) -> QuietTime {
        QuietTime(
            id: UUID(),
            verse: Verse(book: "시편", chapter: 1, verse: 1, text: "복 있는 사람", translation: "개역개정"),
            memo: memo,
            date: Date(),
            status: .committed,
            tags: [],
            isFavorite: isFavorite,
            updatedAt: Date()
        )
    }
}

// MARK: - Mock Repository

final class MockQTRepository: QTRepository {
    var commitCallCount = 0
    var fetchListCallCount = 0
    var getCallCount = 0
    var toggleFavoriteCallCount = 0

    var lastCommittedDraft: QuietTime?
    var lastQuery: QTQuery?
    var lastGetId: UUID?
    var lastToggleFavoriteId: UUID?

    var committedQT: QuietTime?
    var qtList: [QuietTime] = []
    var qtDetail: QuietTime?
    var newFavoriteState: Bool = false
    var shouldThrowNotFound = false

    func commit(_ draft: QuietTime, session: UserSession) async throws -> QuietTime {
        commitCallCount += 1
        lastCommittedDraft = draft

        guard let committed = committedQT else {
            throw DomainError.unknown
        }
        return committed
    }

    func fetchList(query: QTQuery, session: UserSession) async throws -> [QuietTime] {
        fetchListCallCount += 1
        lastQuery = query
        return qtList
    }

    func get(id: UUID, session: UserSession) async throws -> QuietTime {
        getCallCount += 1
        lastGetId = id

        if shouldThrowNotFound {
            throw DomainError.notFound
        }

        guard let detail = qtDetail else {
            throw DomainError.notFound
        }
        return detail
    }

    func updateMemo(id: UUID, newMemo: String, session: UserSession) async throws -> QuietTime {
        fatalError("Not implemented in tests")
    }

    func toggleFavorite(id: UUID, session: UserSession) async throws -> Bool {
        toggleFavoriteCallCount += 1
        lastToggleFavoriteId = id
        return newFavoriteState
    }
}
