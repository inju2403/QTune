//
//  QTDetailView.swift
//  Presentation
//
//  Created by 이승주 on 10/12/25.
//

import SwiftUI
import Domain

public struct QTDetailView: View {
    @StateObject private var viewModel: QTDetailViewModel
    @Environment(\.dismiss) private var dismiss

    let editorViewModelFactory: () -> QTEditorViewModel

    public init(
        viewModel: QTDetailViewModel,
        editorViewModelFactory: @escaping () -> QTEditorViewModel
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.editorViewModelFactory = editorViewModelFactory
    }

    public var body: some View {
        ZStack {
            AppBackgroundView()
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.xl) {
                    // 헤더
                    headerSection()

                    // 상단 말씀 카드
                    verseCardSection()

                    // 템플릿 본문
                    if viewModel.qt.template == "SOAP" {
                        soapContentSection()
                    } else {
                        actsContentSection()
                    }
                }
                .padding(DS.Spacing.l)
            }
        }
        .navigationTitle("QT 기록")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // 즐겨찾기
                Button {
                    Haptics.tap()
                    Task {
                        await viewModel.toggleFavorite()
                    }
                } label: {
                    Image(systemName: viewModel.qt.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(viewModel.qt.isFavorite ? DS.Color.gold : DS.Color.textSecondary)
                }
                .animation(Motion.press, value: viewModel.qt.isFavorite)

                // 메뉴
                Menu {
                    Button {
                        Haptics.tap()
                        viewModel.showEditSheet = true
                    } label: {
                        Label("편집", systemImage: "pencil")
                    }

                    Button {
                        Haptics.tap()
                        viewModel.prepareShare()
                    } label: {
                        Label("공유", systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive) {
                        Haptics.tap()
                        viewModel.confirmDelete()
                    } label: {
                        Label("삭제", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }
        }
        .alert("기록 삭제", isPresented: $viewModel.showDeleteAlert) {
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive) {
                Task {
                    await viewModel.deleteQT()
                    dismiss()
                }
            }
        } message: {
            Text("이 기록을 삭제할까요? 이 작업은 되돌릴 수 없습니다.")
        }
        .sheet(isPresented: $viewModel.showShareSheet) {
            ShareSheet(text: viewModel.shareText)
        }
        .sheet(isPresented: $viewModel.showEditSheet) {
            NavigationStack {
                QTEditorView(
                    draft: viewModel.qt,
                    viewModel: editorViewModelFactory()
                )
                .navigationBarItems(leading: Button("취소") {
                    viewModel.showEditSheet = false
                })
            }
        }
    }
}

// MARK: - Subviews
private extension QTDetailView {
    @ViewBuilder
    func headerSection() -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            HStack(alignment: .top, spacing: DS.Spacing.m) {
                Image(systemName: "book.closed.fill")
                    .foregroundStyle(DS.Color.gold)
                    .font(DS.Font.titleL())

                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text(viewModel.qt.verse.id)
                        .font(DS.Font.titleL(.bold))
                        .foregroundStyle(DS.Color.deepCocoa)

                    Text(formattedDate(viewModel.qt.date))
                        .font(DS.Font.bodyM())
                        .foregroundStyle(DS.Color.textSecondary)
                }

                Spacer()

                Text(viewModel.qt.template)
                    .font(DS.Font.caption(.medium))
                    .foregroundStyle(viewModel.qt.template == "SOAP" ? DS.Color.olive : DS.Color.gold)
                    .padding(.horizontal, DS.Spacing.m)
                    .padding(.vertical, DS.Spacing.xs)
                    .background(
                        viewModel.qt.template == "SOAP"
                            ? DS.Color.olive.opacity(0.15)
                            : DS.Color.gold.opacity(0.15)
                    )
                    .clipShape(Capsule())
            }
        }
        .padding(.top, DS.Spacing.s)
    }

    @ViewBuilder
    func verseCardSection() -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.l) {
            // 영문 본문
            VerseCardView(title: "본문") {
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text(viewModel.qt.verse.text)
                        .lineSpacing(4)

                    Text("\(viewModel.qt.verse.translation) (Public Domain)")
                        .font(DS.Font.caption())
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }

            // 한국어 해석
            if let korean = viewModel.qt.korean, !korean.isEmpty {
                VerseCardView(title: "해설") {
                    let lines = korean.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
                    if lines.count == 2 {
                        VStack(alignment: .leading, spacing: DS.Spacing.s) {
                            Text(String(lines[0]))
                                .font(DS.Font.bodyL(.semibold))
                                .foregroundStyle(DS.Color.gold)

                            Text(String(lines[1]))
                                .lineSpacing(4)
                        }
                    } else {
                        Text(korean)
                            .lineSpacing(4)
                    }
                }
            }

            // 추천 이유
            if let rationale = viewModel.qt.rationale, !rationale.isEmpty {
                VerseCardView(title: "추천 이유") {
                    Text(rationale)
                        .lineSpacing(4)
                }
            }
        }
    }

    @ViewBuilder
    func soapContentSection() -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xl) {
            SectionHeader(icon: "square.and.pencil", title: "나의 묵상")

            if let observation = viewModel.qt.soapObservation, !observation.isEmpty {
                fieldCard(
                    icon: "eye",
                    title: "Observation",
                    subtitle: "관찰",
                    content: observation
                )
            }

            if let application = viewModel.qt.soapApplication, !application.isEmpty {
                fieldCard(
                    icon: "arrow.right.circle",
                    title: "Application",
                    subtitle: "적용",
                    content: application
                )
            }

            if let prayer = viewModel.qt.soapPrayer, !prayer.isEmpty {
                fieldCard(
                    icon: "hands.sparkles",
                    title: "Prayer",
                    subtitle: "기도",
                    content: prayer
                )
            }
        }
    }

    @ViewBuilder
    func actsContentSection() -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xl) {
            SectionHeader(icon: "hands.sparkles", title: "나의 기도")

            if let adoration = viewModel.qt.actsAdoration, !adoration.isEmpty {
                fieldCard(
                    icon: "sparkles",
                    title: "Adoration",
                    subtitle: "경배",
                    content: adoration
                )
            }

            if let confession = viewModel.qt.actsConfession, !confession.isEmpty {
                fieldCard(
                    icon: "heart",
                    title: "Confession",
                    subtitle: "고백",
                    content: confession
                )
            }

            if let thanksgiving = viewModel.qt.actsThanksgiving, !thanksgiving.isEmpty {
                fieldCard(
                    icon: "leaf",
                    title: "Thanksgiving",
                    subtitle: "감사",
                    content: thanksgiving
                )
            }

            if let supplication = viewModel.qt.actsSupplication, !supplication.isEmpty {
                fieldCard(
                    icon: "hands.and.sparkles",
                    title: "Supplication",
                    subtitle: "간구",
                    content: supplication
                )
            }
        }
    }

    @ViewBuilder
    func fieldCard(icon: String, title: String, subtitle: String, content: String) -> some View {
        SoftCard {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                HStack(spacing: DS.Spacing.s) {
                    Image(systemName: icon)
                        .foregroundStyle(DS.Color.gold)
                        .font(DS.Font.bodyL())

                    Text(title)
                        .font(DS.Font.bodyL(.semibold))
                        .foregroundStyle(DS.Color.textPrimary)

                    Text("·")
                        .foregroundStyle(DS.Color.textSecondary)

                    Text(subtitle)
                        .font(DS.Font.bodyM())
                        .foregroundStyle(DS.Color.textSecondary)
                }

                Text(content)
                    .font(DS.Font.bodyM())
                    .foregroundStyle(DS.Color.textPrimary)
                    .lineSpacing(4)
            }
        }
    }

    // MARK: - Helpers
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
