//
//  QTDetailViewModel.swift
//  Presentation
//
//  Created by 이승주 on 10/12/25.
//

import Foundation
import SwiftUI
import Domain

/// QT 상세 화면 ViewModel
public final class QTDetailViewModel: ObservableObject {
    // MARK: - Published State
    @Published public var showDeleteAlert = false
    @Published public var showShareSheet = false
    @Published public var showEditSheet = false
    @Published public var shareText: String = ""

    // MARK: - Dependencies
    private let toggleFavoriteUseCase: ToggleFavoriteUseCase
    private let deleteQTUseCase: DeleteQTUseCase
    private let session: UserSession

    // MARK: - Properties
    public let qt: QuietTime
    public var onDeleted: (() -> Void)?

    // MARK: - Init
    public init(
        qt: QuietTime,
        toggleFavoriteUseCase: ToggleFavoriteUseCase,
        deleteQTUseCase: DeleteQTUseCase,
        session: UserSession
    ) {
        self.qt = qt
        self.toggleFavoriteUseCase = toggleFavoriteUseCase
        self.deleteQTUseCase = deleteQTUseCase
        self.session = session
    }

    // MARK: - Actions
    public func toggleFavorite() async {
        do {
            _ = try await toggleFavoriteUseCase.execute(id: qt.id, session: session)
        } catch {
            print("❌ Failed to toggle favorite: \(error)")
        }
    }

    public func confirmDelete() {
        showDeleteAlert = true
    }

    public func deleteQT() async {
        do {
            try await deleteQTUseCase.execute(id: qt.id, session: session)
            await MainActor.run {
                onDeleted?()
            }
        } catch {
            print("❌ Failed to delete QT: \(error)")
        }
    }

    public func prepareShare() {
        shareText = generateShareText()
        showShareSheet = true
    }

    // MARK: - Share Text Generation
    private func generateShareText() -> String {
        var text = """
        📖 \(qt.verse.id)

        \(qt.verse.text)

        """

        if let korean = qt.korean, !korean.isEmpty {
            text += "\n\(korean)\n"
        }

        if qt.template == "SOAP" {
            if let observation = qt.soapObservation, !observation.isEmpty {
                text += "\n🔎 관찰\n\(observation)\n"
            }
            if let application = qt.soapApplication, !application.isEmpty {
                text += "\n📝 적용\n\(application)\n"
            }
            if let prayer = qt.soapPrayer, !prayer.isEmpty {
                text += "\n🙏 기도\n\(prayer)\n"
            }
        } else {
            if let adoration = qt.actsAdoration, !adoration.isEmpty {
                text += "\n✨ 찬양\n\(adoration)\n"
            }
            if let confession = qt.actsConfession, !confession.isEmpty {
                text += "\n💧 회개\n\(confession)\n"
            }
            if let thanksgiving = qt.actsThanksgiving, !thanksgiving.isEmpty {
                text += "\n💚 감사\n\(thanksgiving)\n"
            }
            if let supplication = qt.actsSupplication, !supplication.isEmpty {
                text += "\n🤲 간구\n\(supplication)\n"
            }
        }

        text += "\n- QTune에서 작성"
        return text
    }
}
