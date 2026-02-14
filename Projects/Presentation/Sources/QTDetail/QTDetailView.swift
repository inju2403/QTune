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
        contentView
            .navigationTitle("QT 기록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .alert("기록 삭제", isPresented: deleteAlertBinding) {
                Button("취소", role: .cancel) {}
                Button("삭제", role: .destructive) {
                    viewModel.send(.deleteQT)
                    dismiss()
                }
            } message: {
                Text("이 기록을 삭제할까요? 이 작업은 되돌릴 수 없습니다.")
            }
            .modifier(ShareSheetsModifier(viewModel: viewModel))
            .modifier(EditSheetModifier(viewModel: viewModel, editorFactory: editorViewModelFactory))
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            HStack(spacing: 12) {
                // 즐겨찾기
                Button {
                    Haptics.tap()
                    viewModel.send(.toggleFavorite)
                } label: {
                    Image(systemName: viewModel.state.qt.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(viewModel.state.qt.isFavorite ? DS.Color.gold : DS.Color.textSecondary)
                }
                .animation(Motion.press, value: viewModel.state.qt.isFavorite)

                // 공유
                Button {
                    Haptics.tap()
                    viewModel.send(.prepareShare)
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(DS.Color.textSecondary)
                }

                // 메뉴
                Menu {
                    Button {
                        Haptics.tap()
                        viewModel.send(.showEditSheet(true))
                    } label: {
                        Label("편집", systemImage: "pencil")
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
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.showDeleteAlert },
            set: { _ in }
        )
    }
}

// MARK: - Subviews
private extension QTDetailView {
    var contentView: some View {
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
    }

    @ViewBuilder
    func headerSection() -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            HStack(alignment: .top, spacing: DS.Spacing.m) {
                Image(systemName: "book.closed.fill")
                    .foregroundStyle(DS.Color.gold)
                    .font(DS.Font.titleL())

                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text(viewModel.state.qt.verse.localizedId)
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
            // 영문 본문 + 비교 역본
            VerseCardView(title: "본문") {
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    // 주 역본
                    DSText.bodyM(viewModel.state.qt.verse.text)
                        .textSelection(.enabled)

                    // 비교 역본이 있으면 표시
                    if let secondaryVerse = viewModel.state.qt.secondaryVerse {
                        DSText.bodyM(secondaryVerse.text)
                            .textSelection(.enabled)
                    }
                }
            }

            // 한국어 해설
            if let korean = viewModel.state.qt.korean, !korean.isEmpty {
                VerseCardView(title: "해설") {
                    DSText.bodyM(korean)
                        .textSelection(.enabled)
                }
            }

            // 이 말씀이 주어진 이유
            if let rationale = viewModel.state.qt.rationale, !rationale.isEmpty {
                VerseCardView(title: "이 말씀이 주어진 이유") {
                    DSText.bodyM(rationale)
                        .textSelection(.enabled)
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
                    DSText.bodyM(observation)
                        .textSelection(.enabled)
                }
            }

            if let application = viewModel.state.qt.soapApplication, !application.isEmpty {
                VerseCardView(title: "Application · 적용") {
                    DSText.bodyM(application)
                        .textSelection(.enabled)
                }
            }

            if let prayer = viewModel.state.qt.soapPrayer, !prayer.isEmpty {
                VerseCardView(title: "Prayer · 기도") {
                    DSText.bodyM(prayer)
                        .textSelection(.enabled)
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
                    DSText.bodyM(adoration)
                        .textSelection(.enabled)
                }
            }

            if let confession = viewModel.state.qt.actsConfession, !confession.isEmpty {
                VerseCardView(title: "Confession · 고백") {
                    DSText.bodyM(confession)
                        .textSelection(.enabled)
                }
            }

            if let thanksgiving = viewModel.state.qt.actsThanksgiving, !thanksgiving.isEmpty {
                VerseCardView(title: "Thanksgiving · 감사") {
                    DSText.bodyM(thanksgiving)
                        .textSelection(.enabled)
                }
            }

            if let supplication = viewModel.state.qt.actsSupplication, !supplication.isEmpty {
                VerseCardView(title: "Supplication · 간구") {
                    DSText.bodyM(supplication)
                        .textSelection(.enabled)
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

// MARK: - Share Format Selection Sheet
struct ShareFormatSelectionSheet: View {
    let viewModel: QTDetailViewModel
    @Environment(\.fontScale) private var fontScale

    var body: some View {
        VStack(spacing: 0) {
            // 타이틀
            VStack(spacing: DS.Spacing.xs) {
                Text("공유 방식 선택")
                    .font(DS.Font.titleL(.bold))
                    .foregroundStyle(DS.Color.deepCocoa)

                Text("어떤 방식으로 공유할까요?")
                    .font(DS.Font.bodyM())
                    .foregroundStyle(DS.Color.textSecondary)
            }
            .padding(.top, DS.Spacing.xl)
            .padding(.bottom, DS.Spacing.l)

            // 옵션
            VStack(spacing: DS.Spacing.m) {
                shareFormatButton(
                    icon: "photo.fill",
                    title: "이미지로 공유",
                    description: "아름다운 이미지 카드로 공유",
                    color: DS.Color.gold,
                    format: .image
                )

                shareFormatButton(
                    icon: "text.alignleft",
                    title: "텍스트로 공유",
                    description: "텍스트 형식으로 공유",
                    color: DS.Color.olive,
                    format: .text
                )
            }
            .padding(.horizontal, DS.Spacing.l)

            Spacer()
        }
    }

    @ViewBuilder
    func shareFormatButton(icon: String, title: String, description: String, color: Color, format: ShareFormat) -> some View {
        Button {
            Haptics.tap()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.send(.selectShareFormat(format))
            }
        } label: {
            HStack(spacing: DS.Spacing.m) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 16 * fontScale.multiplier, weight: .semibold))
                        .foregroundStyle(color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(DS.Font.titleM(.semibold))
                        .foregroundStyle(DS.Color.textPrimary)

                    Text(description)
                        .font(DS.Font.caption())
                        .foregroundStyle(DS.Color.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14 * fontScale.multiplier, weight: .semibold))
                    .foregroundStyle(DS.Color.textSecondary)
            }
            .padding(DS.Spacing.m)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.m)
                    .fill(DS.Color.canvas)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.m)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Share Type Selection Sheet
struct ShareTypeSelectionSheet: View {
    let viewModel: QTDetailViewModel
    @Environment(\.fontScale) private var fontScale

    var body: some View {
        VStack(spacing: 0) {
            // 타이틀
            VStack(spacing: DS.Spacing.xs) {
                Text("공유 방식 선택")
                    .font(DS.Font.titleL(.bold))
                    .foregroundStyle(DS.Color.deepCocoa)

                Text("어떤 방식으로 공유할까요?")
                    .font(DS.Font.bodyM())
                    .foregroundStyle(DS.Color.textSecondary)
            }
            .padding(.top, DS.Spacing.xl)
            .padding(.bottom, DS.Spacing.l)

            // 옵션
            VStack(spacing: DS.Spacing.m) {
                shareTypeButton(
                    icon: "sparkles",
                    title: "핵심 묵상",
                    description: "말씀 + 해설 + 핵심 묵상",
                    color: DS.Color.gold,
                    type: .summary
                )

                shareTypeButton(
                    icon: "doc.text.fill",
                    title: "전체 묵상",
                    description: "말씀 + 해설 + 전체 묵상 내용",
                    color: DS.Color.olive,
                    type: .full
                )
            }
            .padding(.horizontal, DS.Spacing.l)

            Spacer()
        }
    }

    @ViewBuilder
    func shareTypeButton(icon: String, title: String, description: String, color: Color, type: ShareType) -> some View {
        Button {
            Haptics.tap()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.send(.selectShareType(type))
            }
        } label: {
            HStack(spacing: DS.Spacing.m) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 16 * fontScale.multiplier, weight: .semibold))
                        .foregroundStyle(color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(DS.Font.titleM(.semibold))
                        .foregroundStyle(DS.Color.textPrimary)

                    Text(description)
                        .font(DS.Font.caption())
                        .foregroundStyle(DS.Color.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14 * fontScale.multiplier, weight: .semibold))
                    .foregroundStyle(DS.Color.textSecondary)
            }
            .padding(DS.Spacing.m)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.m)
                    .fill(DS.Color.canvas)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.m)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Field Selection Sheet
struct FieldSelectionSheet: View {
    let viewModel: QTDetailViewModel
    @Environment(\.fontScale) private var fontScale

    var body: some View {
        VStack(spacing: 0) {
            // 타이틀
            VStack(spacing: DS.Spacing.xs) {
                Text("묵상 선택")
                    .font(DS.Font.titleL(.bold))
                    .foregroundStyle(DS.Color.deepCocoa)

                Text("공유할 묵상을 선택해주세요")
                    .font(DS.Font.bodyM())
                    .foregroundStyle(DS.Color.textSecondary)
            }
            .padding(.top, DS.Spacing.xl)
            .padding(.bottom, DS.Spacing.l)

            // SOAP 또는 ACTS 필드 선택
            if viewModel.state.qt.template == "SOAP" {
                soapFieldSelection()
            } else {
                actsFieldSelection()
            }

            Spacer()
        }
    }

    @ViewBuilder
    func soapFieldSelection() -> some View {
        VStack(spacing: DS.Spacing.s) {
            fieldButton(icon: "eye", title: "관찰", subtitle: "Observation", color: DS.Color.olive) {
                viewModel.send(.selectSOAPField(.observation))
            }

            fieldButton(icon: "pencil", title: "적용", subtitle: "Application", color: DS.Color.olive) {
                viewModel.send(.selectSOAPField(.application))
            }

            fieldButton(icon: "hands.sparkles", title: "기도", subtitle: "Prayer", color: DS.Color.olive) {
                viewModel.send(.selectSOAPField(.prayer))
            }
        }
        .padding(.horizontal, DS.Spacing.l)
    }

    @ViewBuilder
    func actsFieldSelection() -> some View {
        VStack(spacing: DS.Spacing.s) {
            fieldButton(icon: "sparkles", title: "경배", subtitle: "Adoration", color: DS.Color.gold) {
                viewModel.send(.selectACTSField(.adoration))
            }

            fieldButton(icon: "figure.walk", title: "회개", subtitle: "Confession", color: DS.Color.gold) {
                viewModel.send(.selectACTSField(.confession))
            }

            fieldButton(icon: "heart.fill", title: "감사", subtitle: "Thanksgiving", color: DS.Color.gold) {
                viewModel.send(.selectACTSField(.thanksgiving))
            }

            fieldButton(icon: "hands.and.sparkles.fill", title: "간구", subtitle: "Supplication", color: DS.Color.gold) {
                viewModel.send(.selectACTSField(.supplication))
            }
        }
        .padding(.horizontal, DS.Spacing.l)
    }

    @ViewBuilder
    func fieldButton(icon: String, title: String, subtitle: String, color: Color, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                action()
            }
        } label: {
            HStack(spacing: DS.Spacing.m) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 16 * fontScale.multiplier, weight: .semibold))
                        .foregroundStyle(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DS.Font.titleM(.semibold))
                        .foregroundStyle(DS.Color.textPrimary)

                    Text(subtitle)
                        .font(DS.Font.caption())
                        .foregroundStyle(DS.Color.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14 * fontScale.multiplier, weight: .semibold))
                    .foregroundStyle(DS.Color.textSecondary)
            }
            .padding(DS.Spacing.m)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.m)
                    .fill(DS.Color.canvas)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.m)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Share Sheets Modifier
struct ShareSheetsModifier: ViewModifier {
    let viewModel: QTDetailViewModel

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: shareFormatSelectionBinding) {
                ShareFormatSelectionSheet(viewModel: viewModel)
                    .presentationDetents([.height(280)])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: shareTypeSelectionBinding) {
                ShareTypeSelectionSheet(viewModel: viewModel)
                    .presentationDetents([.height(280)])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: fieldSelectionBinding) {
                FieldSelectionSheet(viewModel: viewModel)
                    .presentationDetents([.height(viewModel.state.qt.template == "SOAP" ? 340 : 450)])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: textShareSheetBinding) {
                ShareSheet(items: [viewModel.state.shareText])
            }
            .sheet(isPresented: imageShareSheetBinding) {
                QTShareCardView(
                    qt: viewModel.state.qt,
                    onShare: {
                        viewModel.send(.shareImageToSystem)
                    }
                )
                .presentationDragIndicator(.hidden)
                .presentationDetents([.large])
            }
            .sheet(isPresented: systemShareSheetBinding) {
                QTShareImageView(qt: viewModel.state.qt)
            }
    }

    private var shareFormatSelectionBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.showShareFormatSelection },
            set: { if !$0 { viewModel.send(.cancelShare) } }
        )
    }

    private var shareTypeSelectionBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.showShareTypeSelection },
            set: { if !$0 { viewModel.send(.cancelShare) } }
        )
    }

    private var fieldSelectionBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.showFieldSelection },
            set: { if !$0 { viewModel.send(.cancelShare) } }
        )
    }

    private var textShareSheetBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.showShareSheet },
            set: { if !$0 { viewModel.send(.closeShareSheet) } }
        )
    }

    private var imageShareSheetBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.showImageShareSheet },
            set: { if !$0 { viewModel.send(.closeShareSheet) } }
        )
    }

    private var systemShareSheetBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.showSystemShareSheet },
            set: { if !$0 { viewModel.send(.closeShareSheet) } }
        )
    }
}

// MARK: - Edit Sheet Modifier
struct EditSheetModifier: ViewModifier {
    let viewModel: QTDetailViewModel
    let editorFactory: () -> QTEditorViewModel

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: editSheetBinding) {
                NavigationStack {
                    QTEditorView(
                        draft: viewModel.state.qt,
                        viewModel: editorFactory()
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

    private var editSheetBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.showEditSheet },
            set: { if !$0 {
                viewModel.send(.showEditSheet(false))
                viewModel.send(.reloadQT)
            } }
        )
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
