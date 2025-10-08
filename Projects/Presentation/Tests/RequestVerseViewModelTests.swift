//
//  RequestVerseViewModelTests.swift
//  PresentationTests
//
//  Created by 이승주 on 10/4/25.
//

import XCTest
import Combine
import Domain
@testable import Presentation

// MARK: - Fake UseCase for Testing
final class FakeGenerateVerseUseCase: GenerateVerseUseCase {
    var shouldFail = false
    var executeCallCount = 0
    var lastPrompt: String?

    func execute(prompt: String) async throws -> GeneratedVerse {
        executeCallCount += 1
        lastPrompt = prompt

        if shouldFail {
            throw NSError(domain: "test", code: -1)
        }

        let verse = Verse(
            book: "이사야",
            chapter: 41,
            verse: 10,
            text: "두려워하지 말라 내가 너와 함께 함이라",
            translation: "개역개정"
        )

        return GeneratedVerse(
            verse: verse,
            reason: "테스트 이유"
        )
    }
}

// MARK: - Tests
@MainActor
final class RequestVerseViewModelTests: XCTestCase {
    var viewModel: RequestVerseViewModel!
    var fakeUseCase: FakeGenerateVerseUseCase!
    var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        try await super.setUp()
        fakeUseCase = FakeGenerateVerseUseCase()
        viewModel = RequestVerseViewModel(generateVerseUseCase: fakeUseCase)
        cancellables = []

        // Clear draft manager for clean state
        await DraftManager.shared.clearTodayDraft(userId: "me")
    }

    override func tearDown() async throws {
        viewModel = nil
        fakeUseCase = nil
        cancellables = nil
        await DraftManager.shared.clearTodayDraft(userId: "me")
        try await super.tearDown()
    }

    // MARK: - Test Case 1: Empty input -> showError
    func testEmptyInput_ShowsError() async {
        // Given
        let expectation = XCTestExpectation(description: "showError effect")
        var receivedError: String?

        viewModel.effect
            .sink { effect in
                if case .showError(let msg) = effect {
                    receivedError = msg
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When: Empty text
        viewModel.send(.tapRequest)

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedError, "오늘의 생각이나 상황을 먼저 입력해 주세요")
        XCTAssertEqual(fakeUseCase.executeCallCount, 0) // Should not call useCase
    }

    // MARK: - Test Case 2: onAppear with existing draft -> showDraftBanner = true
    func testOnAppearWithExistingDraft_ShowsBanner() async {
        // Given: Save a draft first
        let verse = Verse(book: "요한복음", chapter: 3, verse: 16, text: "하나님이 세상을 이처럼 사랑하사", translation: "개역개정")
        let draft = QuietTime(
            verse: verse,
            memo: "테스트 메모",
            date: Date(),
            status: .draft,
            tags: []
        )
        await DraftManager.shared.saveDraft(draft, userId: "me")

        // When
        viewModel.send(.onAppear(userId: "me"))

        // Then: Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second

        XCTAssertTrue(viewModel.state.showDraftBanner)
        XCTAssertNotNil(viewModel.state.todayDraft)
        XCTAssertEqual(viewModel.state.todayDraft?.verse.book, "요한복음")
    }

    // MARK: - Test Case 3: Draft exists + tapRequest -> presentDraftConflict
    func testDraftExistsAndTapRequest_ShowsConflictModal() async {
        // Given: Save a draft and load it
        let verse = Verse(book: "시편", chapter: 23, verse: 1, text: "여호와는 나의 목자시니", translation: "개역개정")
        let draft = QuietTime(
            verse: verse,
            memo: "",
            date: Date(),
            status: .draft,
            tags: []
        )
        await DraftManager.shared.saveDraft(draft, userId: "me")
        viewModel.send(.onAppear(userId: "me"))
        try? await Task.sleep(nanoseconds: 100_000_000) // Wait for draft to load

        viewModel.send(.updateInput("새로운 입력"))

        let expectation = XCTestExpectation(description: "presentDraftConflict effect")
        var conflictPresented = false

        viewModel.effect
            .sink { effect in
                if case .presentDraftConflict = effect {
                    conflictPresented = true
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        viewModel.send(.tapRequest)

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(conflictPresented)
        XCTAssertEqual(fakeUseCase.executeCallCount, 0) // Should not call useCase
    }

    // MARK: - Test Case 4: Normal flow -> navigateToEditor with draft status
    func testNormalFlow_NavigatesToEditorWithDraftStatus() async {
        // Given
        viewModel.send(.updateInput("오늘 힘든 하루였어요. 위로가 필요합니다."))

        let expectation = XCTestExpectation(description: "navigateToEditor effect")
        var capturedDraft: QuietTime?

        viewModel.effect
            .sink { effect in
                if case .navigateToEditor(let qt) = effect {
                    capturedDraft = qt
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        viewModel.send(.tapRequest)

        // Then
        await fulfillment(of: [expectation], timeout: 2.0)

        XCTAssertNotNil(capturedDraft)
        XCTAssertEqual(capturedDraft?.status, .draft)
        XCTAssertEqual(capturedDraft?.memo, "")
        XCTAssertEqual(capturedDraft?.verse.book, "이사야")
        XCTAssertEqual(fakeUseCase.executeCallCount, 1)
        XCTAssertEqual(fakeUseCase.lastPrompt, "오늘 힘든 하루였어요. 위로가 필요합니다.")

        // Verify draft is saved in DraftManager
        let savedDraft = await DraftManager.shared.loadTodayDraft(userId: "me")
        XCTAssertNotNil(savedDraft)
        XCTAssertEqual(savedDraft?.status, .draft)
    }
}
