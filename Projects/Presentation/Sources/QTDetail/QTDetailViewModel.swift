//
//  QTDetailViewModel.swift
//  Presentation
//
//  Created by 이승주 on 10/12/25.
//

import Foundation
import UIKit
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
    private var cachedShareImage: UIImage?

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
            state.showShareFormatSelection = true

        case .selectShareFormat(let format):
            state.selectedShareFormat = format
            state.showShareFormatSelection = false

            if format == .text {
                // 텍스트 공유 → 기존 플로우
                state.showShareTypeSelection = true
            } else {
                // 이미지 공유 → 이미지 생성 후 공유
                cachedShareImage = generateShareImage()
                state.showImageShareSheet = true
            }

        case .selectShareType(let type):
            state.selectedShareType = type
            state.showShareTypeSelection = false

            if type == .full {
                // 전체 묵상 → 바로 공유
                state.shareText = generateFullShareText()
                state.showShareSheet = true
            } else {
                // 선택한 묵상 → 필드 선택 화면으로
                state.showFieldSelection = true
            }

        case .selectSOAPField(let field):
            state.showFieldSelection = false
            state.shareText = generateSummaryShareText(soapField: field)
            state.showShareSheet = true

        case .selectACTSField(let field):
            state.showFieldSelection = false
            state.shareText = generateSummaryShareText(actsField: field)
            state.showShareSheet = true

        case .cancelShare:
            state.showShareFormatSelection = false
            state.showShareTypeSelection = false
            state.showFieldSelection = false
            state.selectedShareFormat = nil
            state.selectedShareType = nil

        case .closeShareSheet:
            state.showShareSheet = false
            state.showImageShareSheet = false
            cachedShareImage = nil

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
                NotificationCenter.default.post(name: .qtDidChange, object: nil)
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

    /// 전체 묵상 공유 텍스트 생성
    private func generateFullShareText() -> String {
        // 날짜 포맷 생성
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd"
        dateFormatter.locale = Locale(identifier: "ko_KR")
        let dateString = dateFormatter.string(from: state.qt.date)

        // 사용자 호칭 생성
        let userTitle: String
        if let profile = userProfile {
            let genderSuffix = profile.gender == .brother ? "형제" : "자매"
            userTitle = "\(profile.nickname) \(genderSuffix)님의 묵상"
        } else {
            userTitle = "나의 묵상"
        }

        var text = "🗓️ \(dateString)\n📝 \(userTitle)\n\n"

        text += """
        📖 \(state.qt.verse.id)

        \(state.qt.verse.text)

        """

        if let korean = state.qt.korean, !korean.isEmpty {
            text += "\n💬 해설\n\(korean)\n"
        }

        if let rationale = state.qt.rationale, !rationale.isEmpty {
            text += "\n✨ 이 말씀이 주어진 이유\n\(rationale)\n"
        }

        text += "\n━━━━━━━━━━━━━━━━\n\n"

        if state.qt.template == "SOAP" {
            if let observation = state.qt.soapObservation, !observation.isEmpty {
                text += "🔎 관찰\n\(observation)\n\n"
            }
            if let application = state.qt.soapApplication, !application.isEmpty {
                text += "📝 적용\n\(application)\n\n"
            }
            if let prayer = state.qt.soapPrayer, !prayer.isEmpty {
                text += "🙏 기도\n\(prayer)\n\n"
            }
        } else {
            if let adoration = state.qt.actsAdoration, !adoration.isEmpty {
                text += "✨ 경배\n\(adoration)\n\n"
            }
            if let confession = state.qt.actsConfession, !confession.isEmpty {
                text += "🧎‍♂️ 회개\n\(confession)\n\n"
            }
            if let thanksgiving = state.qt.actsThanksgiving, !thanksgiving.isEmpty {
                text += "🙏 감사\n\(thanksgiving)\n\n"
            }
            if let supplication = state.qt.actsSupplication, !supplication.isEmpty {
                text += "🤲 간구\n\(supplication)\n\n"
            }
        }

        text += "- QTune에서 작성"
        return text
    }

    /// 요약 공유 텍스트 생성 (SOAP)
    private func generateSummaryShareText(soapField: SOAPField) -> String {
        // 날짜 포맷 생성
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd"
        dateFormatter.locale = Locale(identifier: "ko_KR")
        let dateString = dateFormatter.string(from: state.qt.date)

        // 사용자 호칭 생성
        let userTitle: String
        if let profile = userProfile {
            let genderSuffix = profile.gender == .brother ? "형제" : "자매"
            userTitle = "\(profile.nickname) \(genderSuffix)님의 묵상"
        } else {
            userTitle = "나의 묵상"
        }

        var text = "🗓️ \(dateString)\n📝 \(userTitle)\n\n"

        // 영어 말씀
        text += """
        📖 \(state.qt.verse.id)

        \(state.qt.verse.text)

        """

        // 한글 해설
        if let korean = state.qt.korean, !korean.isEmpty {
            text += "\n💬 해설\n\(korean)\n"
        }

        // 선택한 SOAP 필드만 추가
        text += "\n━━━━━━━━━━━━━━━━\n\n"

        switch soapField {
        case .observation:
            if let observation = state.qt.soapObservation, !observation.isEmpty {
                text += "🔎 관찰\n\(observation)\n\n"
            }
        case .application:
            if let application = state.qt.soapApplication, !application.isEmpty {
                text += "📝 적용\n\(application)\n\n"
            }
        case .prayer:
            if let prayer = state.qt.soapPrayer, !prayer.isEmpty {
                text += "🙏 기도\n\(prayer)\n\n"
            }
        }

        text += "- QTune에서 작성"
        return text
    }

    /// 요약 공유 텍스트 생성 (ACTS)
    private func generateSummaryShareText(actsField: ACTSField) -> String {
        // 날짜 포맷 생성
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd"
        dateFormatter.locale = Locale(identifier: "ko_KR")
        let dateString = dateFormatter.string(from: state.qt.date)

        // 사용자 호칭 생성
        let userTitle: String
        if let profile = userProfile {
            let genderSuffix = profile.gender == .brother ? "형제" : "자매"
            userTitle = "\(profile.nickname) \(genderSuffix)님의 묵상"
        } else {
            userTitle = "나의 묵상"
        }

        var text = "🗓️ \(dateString)\n📝 \(userTitle)\n\n"

        // 영어 말씀
        text += """
        📖 \(state.qt.verse.id)

        \(state.qt.verse.text)

        """

        // 한글 해설
        if let korean = state.qt.korean, !korean.isEmpty {
            text += "\n💬 해설\n\(korean)\n"
        }

        // 선택한 ACTS 필드만 추가
        text += "\n━━━━━━━━━━━━━━━━\n\n"

        switch actsField {
        case .adoration:
            if let adoration = state.qt.actsAdoration, !adoration.isEmpty {
                text += "✨ 경배\n\(adoration)\n\n"
            }
        case .confession:
            if let confession = state.qt.actsConfession, !confession.isEmpty {
                text += "🧎‍♂️ 회개\n\(confession)\n\n"
            }
        case .thanksgiving:
            if let thanksgiving = state.qt.actsThanksgiving, !thanksgiving.isEmpty {
                text += "🙏 감사\n\(thanksgiving)\n\n"
            }
        case .supplication:
            if let supplication = state.qt.actsSupplication, !supplication.isEmpty {
                text += "🤲 간구\n\(supplication)\n\n"
            }
        }

        text += "- QTune에서 작성"
        return text
    }

    // MARK: - Image Generation

    /// 캐시된 공유 이미지 가져오기
    public func getShareImage() -> UIImage? {
        return cachedShareImage
    }

    /// 공유용 이미지 생성
    private func generateShareImage() -> UIImage {
        let size = CGSize(width: 1080, height: 1350) // Instagram 세로형
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            // 1. 그라데이션 배경
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(red: 0.98, green: 0.85, blue: 0.70, alpha: 1.0).cgColor, // 연한 gold
                    UIColor(red: 0.95, green: 0.75, blue: 0.60, alpha: 1.0).cgColor, // 중간 peach
                    UIColor(red: 0.85, green: 0.65, blue: 0.50, alpha: 1.0).cgColor  // 진한 sunset
                ] as CFArray,
                locations: [0.0, 0.5, 1.0]
            )!

            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: size.width / 2, y: 0),
                end: CGPoint(x: size.width / 2, y: size.height),
                options: []
            )

            // 2. 상단 섹션 (성경 구절 참조 + 날짜)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy.MM.dd"
            let dateString = dateFormatter.string(from: state.qt.date)

            let headerText = "\(state.qt.verse.id)\n\(dateString)"
            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 36, weight: .bold),
                .foregroundColor: UIColor(red: 0.3, green: 0.2, blue: 0.15, alpha: 1.0) // 진한 cocoa
            ]
            let headerSize = headerText.boundingRect(
                with: CGSize(width: size.width - 160, height: .greatestFiniteMagnitude),
                options: .usesLineFragmentOrigin,
                attributes: headerAttributes,
                context: nil
            ).size
            headerText.draw(
                in: CGRect(x: 80, y: 120, width: size.width - 160, height: headerSize.height),
                withAttributes: headerAttributes
            )

            // 3. 중앙 섹션 (영어 본문)
            let verseText = state.qt.verse.text
            let verseAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 32, weight: .medium),
                .foregroundColor: UIColor(red: 0.2, green: 0.15, blue: 0.1, alpha: 1.0),
                .paragraphStyle: {
                    let style = NSMutableParagraphStyle()
                    style.lineSpacing = 12
                    return style
                }()
            ]
            let verseSize = verseText.boundingRect(
                with: CGSize(width: size.width - 160, height: .greatestFiniteMagnitude),
                options: .usesLineFragmentOrigin,
                attributes: verseAttributes,
                context: nil
            ).size
            let verseY = (size.height - verseSize.height) / 2
            verseText.draw(
                in: CGRect(x: 80, y: verseY, width: size.width - 160, height: verseSize.height),
                withAttributes: verseAttributes
            )

            // 4. 한글 해설 (있으면)
            if let korean = state.qt.korean, !korean.isEmpty {
                let koreanAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 28, weight: .regular),
                    .foregroundColor: UIColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 1.0),
                    .paragraphStyle: {
                        let style = NSMutableParagraphStyle()
                        style.lineSpacing = 10
                        return style
                    }()
                ]
                let koreanSize = korean.boundingRect(
                    with: CGSize(width: size.width - 160, height: .greatestFiniteMagnitude),
                    options: .usesLineFragmentOrigin,
                    attributes: koreanAttributes,
                    context: nil
                ).size
                korean.draw(
                    in: CGRect(x: 80, y: verseY + verseSize.height + 40, width: size.width - 160, height: koreanSize.height),
                    withAttributes: koreanAttributes
                )
            }

            // 5. 하단 워터마크
            let watermark = "QTune에서 작성"
            let watermarkAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .regular),
                .foregroundColor: UIColor(red: 0.5, green: 0.4, blue: 0.3, alpha: 0.8)
            ]
            let watermarkSize = watermark.size(withAttributes: watermarkAttributes)
            watermark.draw(
                at: CGPoint(
                    x: (size.width - watermarkSize.width) / 2,
                    y: size.height - 100
                ),
                withAttributes: watermarkAttributes
            )
        }
    }
}
