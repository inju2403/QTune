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
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
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
            .padding(16)
        }
        .navigationTitle("QT 기록")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // 즐겨찾기
                Button(action: {
                    Task {
                        await viewModel.toggleFavorite()
                    }
                }) {
                    Image(systemName: viewModel.qt.isFavorite ? "star.fill" : "star")
                        .foregroundColor(viewModel.qt.isFavorite ? .yellow : .secondary)
                }

                // 메뉴
                Menu {
                    Button(action: {
                        viewModel.showEditSheet = true
                    }) {
                        Label("편집", systemImage: "pencil")
                    }

                    Button(action: {
                        viewModel.prepareShare()
                    }) {
                        Label("공유", systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive, action: {
                        viewModel.confirmDelete()
                    }) {
                        Label("삭제", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(viewModel.qt.verse.id)
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Text(viewModel.qt.template)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(viewModel.qt.template == "SOAP" ? Color.blue.opacity(0.1) : Color.purple.opacity(0.1))
                    .foregroundColor(viewModel.qt.template == "SOAP" ? .blue : .purple)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            Text(formattedDate(viewModel.qt.date))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    func verseCardSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // 영문 본문
            VStack(alignment: .leading, spacing: 8) {
                Text("Original")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(viewModel.qt.verse.text)
                    .font(.body)
                    .foregroundColor(.primary)

                Text("\(viewModel.qt.verse.translation) (Public Domain)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // 한국어 해석
            if let korean = viewModel.qt.korean, !korean.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "sparkle")
                            .foregroundColor(.purple)
                        Text("구절 해설")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    let lines = korean.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
                    if lines.count == 2 {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(lines[0]))
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.purple)

                            Text(String(lines[1]))
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                    } else {
                        Text(korean)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }
            }

            // 추천 이유
            if let rationale = viewModel.qt.rationale, !rationale.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("추천 이유")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(rationale)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    func soapContentSection() -> some View {
        VStack(alignment: .leading, spacing: 24) {
            if let observation = viewModel.qt.soapObservation, !observation.isEmpty {
                fieldCard(
                    title: "O 🔎 Observation",
                    content: observation
                )
            }

            if let application = viewModel.qt.soapApplication, !application.isEmpty {
                fieldCard(
                    title: "A 📝 Application",
                    content: application
                )
            }

            if let prayer = viewModel.qt.soapPrayer, !prayer.isEmpty {
                fieldCard(
                    title: "P 🙏 Prayer",
                    content: prayer
                )
            }
        }
    }

    @ViewBuilder
    func actsContentSection() -> some View {
        VStack(alignment: .leading, spacing: 24) {
            if let adoration = viewModel.qt.actsAdoration, !adoration.isEmpty {
                fieldCard(
                    title: "A ✨ Adoration",
                    content: adoration
                )
            }

            if let confession = viewModel.qt.actsConfession, !confession.isEmpty {
                fieldCard(
                    title: "C 💧 Confession",
                    content: confession
                )
            }

            if let thanksgiving = viewModel.qt.actsThanksgiving, !thanksgiving.isEmpty {
                fieldCard(
                    title: "T 💚 Thanksgiving",
                    content: thanksgiving
                )
            }

            if let supplication = viewModel.qt.actsSupplication, !supplication.isEmpty {
                fieldCard(
                    title: "S 🤲 Supplication",
                    content: supplication
                )
            }
        }
    }

    @ViewBuilder
    func fieldCard(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            Text(content)
                .font(.body)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
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
