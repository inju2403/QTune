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
                // 핵심 묵상 → SOAP는 Prayer, ACTS는 Thanksgiving
                if state.qt.template == "SOAP" {
                    state.shareText = generateSummaryShareText(soapField: .prayer)
                } else {
                    state.shareText = generateSummaryShareText(actsField: .thanksgiving)
                }
                state.showShareSheet = true
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
            state.showSystemShareSheet = false
            cachedShareImage = nil

        case .shareImageToSystem:
            state.showSystemShareSheet = true

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

    /// 공유용 이미지 생성 (스크린샷 디자인 동일)
    private func generateShareImage() -> UIImage {
        let size = CGSize(width: 1080, height: 1920) // 9:16 비율
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            // 1. 밝은 베이지 배경
            UIColor(red: 0.96, green: 0.94, blue: 0.90, alpha: 1.0).setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let padding: CGFloat = 80
            let contentWidth = size.width - (padding * 2)
            var currentY: CGFloat = 150

            // 2. 날짜 (중앙 상단)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy.MM.dd"
            let dateString = dateFormatter.string(from: state.qt.date)

            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 32, weight: .regular),
                .foregroundColor: UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
            ]
            let dateSize = dateString.size(withAttributes: dateAttributes)
            dateString.draw(
                at: CGPoint(x: (size.width - dateSize.width) / 2, y: currentY),
                withAttributes: dateAttributes
            )
            currentY += dateSize.height + 80

            // 3. 구절 참조 (왼쪽 정렬, 볼드)
            let verseRef = state.qt.verse.id
            let verseRefAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 42, weight: .bold),
                .foregroundColor: UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
            ]
            let verseRefSize = verseRef.size(withAttributes: verseRefAttributes)
            verseRef.draw(
                at: CGPoint(x: padding, y: currentY),
                withAttributes: verseRefAttributes
            )
            currentY += verseRefSize.height + 50

            // 4. 말씀 본문 (한글 또는 영어)
            let verseText = state.qt.verse.text
            let verseAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 38, weight: .regular),
                .foregroundColor: UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0),
                .paragraphStyle: {
                    let style = NSMutableParagraphStyle()
                    style.lineSpacing = 14
                    return style
                }()
            ]
            let verseSize = verseText.boundingRect(
                with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                options: .usesLineFragmentOrigin,
                attributes: verseAttributes,
                context: nil
            ).size
            verseText.draw(
                in: CGRect(x: padding, y: currentY, width: contentWidth, height: verseSize.height),
                withAttributes: verseAttributes
            )
            currentY += verseSize.height + 60

            // 5. 해설
            if let korean = state.qt.korean, !korean.isEmpty {
                // "해설" 레이블
                let explanationLabel = "해설"
                let labelAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 32, weight: .semibold),
                    .foregroundColor: UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
                ]
                let labelSize = explanationLabel.size(withAttributes: labelAttributes)
                explanationLabel.draw(
                    at: CGPoint(x: padding, y: currentY),
                    withAttributes: labelAttributes
                )
                currentY += labelSize.height + 25

                // 해설 내용
                let explanationAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 34, weight: .regular),
                    .foregroundColor: UIColor(red: 0.25, green: 0.25, blue: 0.25, alpha: 1.0),
                    .paragraphStyle: {
                        let style = NSMutableParagraphStyle()
                        style.lineSpacing = 12
                        return style
                    }()
                ]
                let explanationSize = korean.boundingRect(
                    with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                    options: .usesLineFragmentOrigin,
                    attributes: explanationAttributes,
                    context: nil
                ).size
                korean.draw(
                    in: CGRect(x: padding, y: currentY, width: contentWidth, height: explanationSize.height),
                    withAttributes: explanationAttributes
                )
                currentY += explanationSize.height + 60
            }

            // 6. 핵심 묵상 (SOAP → Prayer, ACTS → Thanksgiving)
            var meditationLabel = ""
            var meditationContent = ""

            if state.qt.template == "SOAP" {
                meditationLabel = "기도"
                meditationContent = state.qt.soapPrayer ?? ""
            } else {
                meditationLabel = "감사"
                meditationContent = state.qt.actsThanksgiving ?? ""
            }

            if !meditationContent.isEmpty {
                // 묵상 레이블
                let mLabelAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 32, weight: .semibold),
                    .foregroundColor: UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
                ]
                let mLabelSize = meditationLabel.size(withAttributes: mLabelAttributes)
                meditationLabel.draw(
                    at: CGPoint(x: padding, y: currentY),
                    withAttributes: mLabelAttributes
                )
                currentY += mLabelSize.height + 25

                // 묵상 내용
                let mContentAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 34, weight: .regular),
                    .foregroundColor: UIColor(red: 0.25, green: 0.25, blue: 0.25, alpha: 1.0),
                    .paragraphStyle: {
                        let style = NSMutableParagraphStyle()
                        style.lineSpacing = 12
                        return style
                    }()
                ]
                let mContentSize = meditationContent.boundingRect(
                    with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                    options: .usesLineFragmentOrigin,
                    attributes: mContentAttributes,
                    context: nil
                ).size
                meditationContent.draw(
                    in: CGRect(x: padding, y: currentY, width: contentWidth, height: mContentSize.height),
                    withAttributes: mContentAttributes
                )
            }

            // 7. 하단 워터마크 "QTune" (중앙)
            let watermark = "QTune"
            let watermarkAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 28, weight: .regular),
                .foregroundColor: UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
            ]
            let watermarkSize = watermark.size(withAttributes: watermarkAttributes)
            watermark.draw(
                at: CGPoint(
                    x: (size.width - watermarkSize.width) / 2,
                    y: size.height - 120
                ),
                withAttributes: watermarkAttributes
            )
        }
    }
}
