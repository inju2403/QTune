//
//  QTDetailViewModel.swift
//  Presentation
//
//  Created by 이승주 on 10/12/25.
//

import Foundation
import Domain

/// QT 상세 화면 ViewModel
@Observable
public final class QTDetailViewModel {
    // MARK: - State
    public private(set) var state: QTDetailState

    // MARK: - Dependencies
    private let toggleFavoriteUseCase: ToggleFavoriteUseCase
    private let deleteQTUseCase: DeleteQTUseCase
    private let getQTDetailUseCase: GetQTDetailUseCase
    private let session: UserSession
    private let userProfile: UserProfile?

    // MARK: - Properties
    public var onDeleted: (() -> Void)?

    // MARK: - Init
    public init(
        qt: QuietTime,
        toggleFavoriteUseCase: ToggleFavoriteUseCase,
        deleteQTUseCase: DeleteQTUseCase,
        getQTDetailUseCase: GetQTDetailUseCase,
        session: UserSession,
        userProfile: UserProfile?
    ) {
        self.state = QTDetailState(qt: qt)
        self.toggleFavoriteUseCase = toggleFavoriteUseCase
        self.deleteQTUseCase = deleteQTUseCase
        self.getQTDetailUseCase = getQTDetailUseCase
        self.session = session
        self.userProfile = userProfile
    }

    // MARK: - Send Action
    public func send(_ action: QTDetailAction) {
        switch action {
        case .toggleFavorite:
            Task { await toggleFavorite() }

        case .confirmDelete:
            state.showDeleteAlert = true

        case .deleteQT:
            Task { await deleteQT() }

        case .prepareShare:
            state.shareText = generateShareText()
            state.showShareSheet = true

        case .closeShareSheet:
            state.showShareSheet = false

        case .showEditSheet(let show):
            state.showEditSheet = show

        case .reloadQT:
            Task { await reloadQT() }
        }
    }

    // MARK: - Actions
    @MainActor
    private func toggleFavorite() async {
        // Optimistic update
        state.qt.isFavorite.toggle()

        // 백그라운드 동기화
        Task.detached { [weak self, qtId = state.qt.id, session] in
            guard let self = self else { return }
            do {
                _ = try await self.toggleFavoriteUseCase.execute(id: qtId, session: session)
            } catch {
                await MainActor.run {
                    self.state.qt.isFavorite.toggle() // 롤백
                }
                print("❌ Failed to toggle favorite: \(error)")
            }
        }
    }

    private func deleteQT() async {
        do {
            try await deleteQTUseCase.execute(id: state.qt.id, session: session)
            await MainActor.run {
                onDeleted?()
            }
        } catch {
            print("❌ Failed to delete QT: \(error)")
        }
    }

    private func reloadQT() async {
        do {
            let updatedQT = try await getQTDetailUseCase.execute(id: state.qt.id, session: session)
            await MainActor.run {
                state.qt = updatedQT
            }
        } catch {
            print("❌ Failed to reload QT: \(error)")
        }
    }

    // MARK: - Share Text Generation
    private func generateShareText() -> String {
        var text = """
        📖 \(state.qt.verse.id)

        \(state.qt.verse.text)

        """

        if let korean = state.qt.korean, !korean.isEmpty {
            text += "\n\(korean)\n"
        }

        if state.qt.template == "SOAP" {
            if let observation = state.qt.soapObservation, !observation.isEmpty {
                text += "\n🔎 관찰\n\(observation)\n"
            }
            if let application = state.qt.soapApplication, !application.isEmpty {
                text += "\n📝 적용\n\(application)\n"
            }
            if let prayer = state.qt.soapPrayer, !prayer.isEmpty {
                text += "\n🙏 기도\n\(prayer)\n"
            }
        } else {
            if let adoration = state.qt.actsAdoration, !adoration.isEmpty {
                text += "\n✨ 찬양\n\(adoration)\n"
            }
            if let confession = state.qt.actsConfession, !confession.isEmpty {
                text += "\n💧 회개\n\(confession)\n"
            }
            if let thanksgiving = state.qt.actsThanksgiving, !thanksgiving.isEmpty {
                text += "\n💚 감사\n\(thanksgiving)\n"
            }
            if let supplication = state.qt.actsSupplication, !supplication.isEmpty {
                text += "\n🤲 간구\n\(supplication)\n"
            }
        }

        text += "\n- QTune에서 작성"
        return text
    }
}
