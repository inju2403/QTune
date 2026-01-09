//
//  QTDetailView.swift
//  Presentation
//
//  Created by 이승주 on 10/12/25.
//

import SwiftUI
import Domain

public struct QTDetailView: View {
    @State private var viewModel: QTDetailViewModel
    @Environment(\.dismiss) private var dismiss

    let editorViewModelFactory: () -> QTEditorViewModel

    public init(
        viewModel: QTDetailViewModel,
        editorViewModelFactory: @escaping () -> QTEditorViewModel
    ) {
        _viewModel = State(wrappedValue: viewModel)
        self.editorViewModelFactory = editorViewModelFactory
    }

    public var body: some View {
        ZStack {
            CrossSunsetBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.xl) {
                    // 헤더
                    headerSection()

                    // 상단 말씀 카드
                    verseCardSection()

                    // 템플릿 본문
                    if viewModel.state.qt.template == "SOAP" {
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
                    viewModel.send(.toggleFavorite)
                } label: {
                    Image(systemName: viewModel.state.qt.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(viewModel.state.qt.isFavorite ? DS.Color.gold : DS.Color.textSecondary)
                }
                .animation(Motion.press, value: viewModel.state.qt.isFavorite)

                // 메뉴
                Menu {
                    Button {
                        Haptics.tap()
                        viewModel.send(.showEditSheet(true))
                    } label: {
                        Label("편집", systemImage: "pencil")
                    }

                    Button {
                        Haptics.tap()
                        viewModel.send(.prepareShare)
                    } label: {
                        Label("공유", systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive) {
                        Haptics.tap()
                        viewModel.send(.confirmDelete)
                    } label: {
                        Label("삭제", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }
        }
        .alert("기록 삭제", isPresented: Binding(
            get: { viewModel.state.showDeleteAlert },
            set: { _ in }
        )) {
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive) {
                viewModel.send(.deleteQT)
                dismiss()
            }
        } message: {
            Text("이 기록을 삭제할까요? 이 작업은 되돌릴 수 없습니다.")
        }
        .sheet(isPresented: Binding(
            get: { viewModel.state.showShareSheet },
            set: { if !$0 { viewModel.send(.closeShareSheet) } }
        )) {
            ShareSheet(text: viewModel.state.shareText)
        }
        .sheet(isPresented: Binding(
            get: { viewModel.state.showEditSheet },
            set: { if !$0 {
                viewModel.send(.showEditSheet(false))
                viewModel.send(.reloadQT)
            } }
        )) {
            NavigationStack {
                QTEditorView(
                    draft: viewModel.state.qt,
                    viewModel: editorViewModelFactory()
                )
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("취소") {
                            viewModel.send(.showEditSheet(false))
                        }
                    }
                }
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
                    Text(viewModel.state.qt.verse.id)
                        .font(DS.Font.titleM(.bold))
                        .foregroundStyle(DS.Color.deepCocoa)

                    Text(formattedDate(viewModel.state.qt.date))
                        .font(DS.Font.bodyM())
                        .foregroundStyle(DS.Color.textSecondary)
                }

                Spacer()

                Text(viewModel.state.qt.template)
                    .font(DS.Font.caption(.medium))
                    .foregroundStyle(viewModel.state.qt.template == "SOAP" ? DS.Color.olive : DS.Color.gold)
                    .padding(.horizontal, DS.Spacing.m)
                    .padding(.vertical, DS.Spacing.xs)
                    .background(
                        viewModel.state.qt.template == "SOAP"
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
        VStack(alignment: .leading, spacing: 11) {
            // 영문 본문
            VerseCardView(title: "본문") {
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text(viewModel.state.qt.verse.text)
                        .lineSpacing(4)

                    Text("\(viewModel.state.qt.verse.translation) (Public Domain)")
                        .font(DS.Font.caption())
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }

            // 한국어 해석
            if let korean = viewModel.state.qt.korean, !korean.isEmpty {
                VerseCardView(title: "해설") {
                    let lines = korean.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
                    if lines.count == 2 {
                        VStack(alignment: .leading, spacing: DS.Spacing.s) {
                            Text(String(lines[0]))
                                .font(DS.Font.bodyM(.semibold))
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
            if let rationale = viewModel.state.qt.rationale, !rationale.isEmpty {
                VerseCardView(title: "추천 이유") {
                    Text(rationale)
                        .lineSpacing(4)
                }
            }
        }
    }

    @ViewBuilder
    func soapContentSection() -> some View {
        VStack(alignment: .leading, spacing: 11) {
            SectionHeader(icon: "square.and.pencil", title: "나의 묵상")

            if let observation = viewModel.state.qt.soapObservation, !observation.isEmpty {
                VerseCardView(title: "Observation · 관찰") {
                    Text(observation)
                        .lineSpacing(4)
                }
            }

            if let application = viewModel.state.qt.soapApplication, !application.isEmpty {
                VerseCardView(title: "Application · 적용") {
                    Text(application)
                        .lineSpacing(4)
                }
            }

            if let prayer = viewModel.state.qt.soapPrayer, !prayer.isEmpty {
                VerseCardView(title: "Prayer · 기도") {
                    Text(prayer)
                        .lineSpacing(4)
                }
            }
        }
    }

    @ViewBuilder
    func actsContentSection() -> some View {
        VStack(alignment: .leading, spacing: 11) {
            SectionHeader(icon: "hands.sparkles", title: "나의 기도")

            if let adoration = viewModel.state.qt.actsAdoration, !adoration.isEmpty {
                VerseCardView(title: "Adoration · 경배") {
                    Text(adoration)
                        .lineSpacing(4)
                }
            }

            if let confession = viewModel.state.qt.actsConfession, !confession.isEmpty {
                VerseCardView(title: "Confession · 고백") {
                    Text(confession)
                        .lineSpacing(4)
                }
            }

            if let thanksgiving = viewModel.state.qt.actsThanksgiving, !thanksgiving.isEmpty {
                VerseCardView(title: "Thanksgiving · 감사") {
                    Text(thanksgiving)
                        .lineSpacing(4)
                }
            }

            if let supplication = viewModel.state.qt.actsSupplication, !supplication.isEmpty {
                VerseCardView(title: "Supplication · 간구") {
                    Text(supplication)
                        .lineSpacing(4)
                }
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
