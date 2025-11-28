//
//  QTEditorWizardView.swift
//  Presentation
//
//  Created by 이승주 on 10/19/25.
//

import SwiftUI
import Domain

// MARK: - Step Enums

enum SoapStep: Int, CaseIterable {
    case observation
    case application
    case prayer
}

enum ActsStep: Int, CaseIterable {
    case adoration
    case confession
    case thanksgiving
    case supplication
}

// MARK: - QTEditorWizardView

public struct QTEditorWizardView: View {
    let template: TemplateKind
    let verseEN: String
    let verseRef: String
    let explKR: String
    let verse: Verse
    let commitQTUseCase: CommitQTUseCase
    let session: UserSession
    let onSaveComplete: () -> Void

    @State private var soapStep: SoapStep = .observation
    @State private var actsStep: ActsStep = .adoration

    // SOAP 입력값
    @State private var observation = ""
    @State private var application = ""
    @State private var prayer = ""

    // ACTS 입력값
    @State private var adoration = ""
    @State private var confession = ""
    @State private var thanksgiving = ""
    @State private var supplication = ""

    // 저장 상태
    @State private var isSaving = false
    @State private var showSaveSuccessToast = false
    @State private var showSaveErrorAlert = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss

    public init(
        template: TemplateKind,
        verseEN: String,
        verseRef: String,
        explKR: String,
        verse: Verse,
        commitQTUseCase: CommitQTUseCase,
        session: UserSession,
        onSaveComplete: @escaping () -> Void
    ) {
        self.template = template
        self.verseEN = verseEN
        self.verseRef = verseRef
        self.explKR = explKR
        self.verse = verse
        self.commitQTUseCase = commitQTUseCase
        self.session = session
        self.onSaveComplete = onSaveComplete
    }

    public var body: some View {
        ZStack {
            CrossSunsetBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 상단: 영어 말씀 + 해설
                verseHeader()

                // 중앙: 현재 스텝의 입력 카드
                ScrollView {
                    ZStack {
                        if template == .soap {
                            StepPager(currentIndex: soapStep.rawValue, total: SoapStep.allCases.count) {
                                switch soapStep {
                                case .observation:
                                    SingleFieldCard(
                                        title: "Observation · 관찰",
                                        placeholder: "무엇이 보이나요?",
                                        text: $observation
                                    )
                                case .application:
                                    SingleFieldCard(
                                        title: "Application · 적용",
                                        placeholder: "어떻게 살기로 결단하나요?",
                                        text: $application
                                    )
                                case .prayer:
                                    SingleFieldCard(
                                        title: "Prayer · 기도",
                                        placeholder: "이 말씀으로 드리는 기도",
                                        text: $prayer
                                    )
                                }
                            }
                        } else {
                            StepPager(currentIndex: actsStep.rawValue, total: ActsStep.allCases.count) {
                                switch actsStep {
                                case .adoration:
                                    SingleFieldCard(
                                        title: "Adoration · 찬양",
                                        placeholder: "주님은 어떤 분이신가요?",
                                        text: $adoration
                                    )
                                case .confession:
                                    SingleFieldCard(
                                        title: "Confession · 고백",
                                        placeholder: "회개할 것은 무엇인가요?",
                                        text: $confession
                                    )
                                case .thanksgiving:
                                    SingleFieldCard(
                                        title: "Thanksgiving · 감사",
                                        placeholder: "감사 제목을 적어보세요",
                                        text: $thanksgiving
                                    )
                                case .supplication:
                                    SingleFieldCard(
                                        title: "Supplication · 간구",
                                        placeholder: "구하는 바를 적어보세요",
                                        text: $supplication
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }

                // 하단: 이전/다음 버튼
                HStack(spacing: 12) {
                    // 이전 버튼 (첫 스텝이 아닐 때만 표시)
                    if !isFirstStep {
                        Button {
                            Haptics.tap()
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                goPrevious()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("이전")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundStyle(DS.Color.deepCocoa)
                            .frame(height: 50)
                            .padding(.horizontal, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(DS.Color.canvas.opacity(0.9))
                                    .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // 다음/저장 버튼 (확장)
                    Button {
                        Haptics.tap()
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            goNext()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(nextTitle)
                                .font(.system(size: 17, weight: .bold))
                            if !isLastStep {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(
                                        colors: [DS.Color.mocha, DS.Color.deepCocoa],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: DS.Color.mocha.opacity(0.3), radius: 8, y: 4)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    DS.Color.background.opacity(0.95)
                        .ignoresSafeArea(edges: .bottom)
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("QT 작성")
        .toolbar(.hidden, for: .tabBar)
        .alert("저장 실패", isPresented: $showSaveErrorAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("저장에 실패했어요. 다시 시도해 주세요.")
        }
        .overlay(alignment: .bottom) {
            if showSaveSuccessToast {
                successToast()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(Motion.appear, value: showSaveSuccessToast)
            }
        }
    }

    // MARK: - Success Toast

    @ViewBuilder
    private func successToast() -> some View {
        SoftCard {
            HStack(spacing: DS.Spacing.m) {
                ZStack {
                    Circle()
                        .fill(DS.Color.success.opacity(0.2))
                        .frame(width: 32, height: 32)
                        .blur(radius: 6)

                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(DS.Color.success)
                        .font(DS.Font.titleM())
                }

                Text("기록이 저장되었습니다")
                    .font(DS.Font.bodyL(.semibold))
                    .foregroundStyle(DS.Color.textPrimary)
            }
        }
        .padding(.horizontal, DS.Spacing.l)
        .padding(.bottom, DS.Spacing.xxl)
    }

    // MARK: - Subviews

    @ViewBuilder
    private func verseHeader() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // 영어 말씀
            VStack(alignment: .leading, spacing: 12) {
                // 성경 구절 참조
                HStack(spacing: 6) {
                    Image(systemName: "book.closed.fill")
                        .foregroundStyle(DS.Color.gold)
                        .font(.system(size: 14))
                    Text(verseRef)
                        .font(DS.Font.caption(.semibold))
                        .foregroundStyle(DS.Color.deepCocoa)
                }

                Text(verseEN)
                    .font(DS.Font.verse(18, .regular))
                    .foregroundStyle(DS.Color.textPrimary)
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
            .background(DS.Color.canvas.opacity(0.9))
            .cornerRadius(DS.Radius.m)
            .padding(.horizontal, 20)
            .padding(.top, 12)

            // 한글 해설 (영구 표시)
            if !explKR.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(DS.Color.gold)
                            .font(.system(size: 12))
                        Text("해설")
                            .font(DS.Font.caption(.semibold))
                            .foregroundStyle(DS.Color.deepCocoa)
                    }

                    Text(explKR)
                        .font(DS.Font.bodyM())
                        .foregroundStyle(DS.Color.textPrimary)
                        .lineSpacing(5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(16)
                .background(DS.Color.canvas.opacity(0.9))
                .cornerRadius(DS.Radius.m)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 12)
            } else {
                Spacer()
                    .frame(height: 12)
            }
        }
        .background(DS.Color.background.opacity(0.95))
    }

    private var isFirstStep: Bool {
        switch template {
        case .soap:
            return soapStep == .observation
        case .acts:
            return actsStep == .adoration
        }
    }

    private var isLastStep: Bool {
        switch template {
        case .soap:
            return soapStep == .prayer
        case .acts:
            return actsStep == .supplication
        }
    }

    private var nextTitle: String {
        isLastStep ? "저장" : "다음"
    }

    private func goPrevious() {
        switch template {
        case .soap:
            if let prev = SoapStep(rawValue: soapStep.rawValue - 1) {
                soapStep = prev
            }
        case .acts:
            if let prev = ActsStep(rawValue: actsStep.rawValue - 1) {
                actsStep = prev
            }
        }
    }

    private func goNext() {
        switch template {
        case .soap:
            if let next = SoapStep(rawValue: soapStep.rawValue + 1) {
                soapStep = next
            } else {
                saveAndFinish()
            }
        case .acts:
            if let next = ActsStep(rawValue: actsStep.rawValue + 1) {
                actsStep = next
            } else {
                saveAndFinish()
            }
        }
    }

    private func saveAndFinish() {
        guard !isSaving else { return }

        Task {
            await MainActor.run {
                isSaving = true
            }

            do {
                // QuietTime 생성
                var qt = QuietTime(
                    verse: verse,
                    korean: explKR,
                    rationale: nil,
                    date: Date(),
                    status: .draft,
                    template: template == .soap ? "SOAP" : "ACTS"
                )

                // 템플릿별 필드 설정
                if template == .soap {
                    qt.soapObservation = observation
                    qt.soapApplication = application
                    qt.soapPrayer = prayer
                } else {
                    qt.actsAdoration = adoration
                    qt.actsConfession = confession
                    qt.actsThanksgiving = thanksgiving
                    qt.actsSupplication = supplication
                }

                // 저장
                _ = try await commitQTUseCase.execute(draft: qt, session: session)

                // 성공
                await MainActor.run {
                    Haptics.success()
                    showSaveSuccessToast = true
                    isSaving = false

                    // 1초 후 dismiss + 기록 탭으로 이동
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        dismiss()

                        // dismiss 후 기록 탭으로 전환
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onSaveComplete()
                        }
                    }
                }
            } catch {
                // 실패
                await MainActor.run {
                    isSaving = false
                    showSaveErrorAlert = true
                }
            }
        }
    }
}

// MARK: - StepPager (부드러운 페이드+스케일 전환)

struct StepPager<Content: View>: View {
    let currentIndex: Int
    let total: Int
    @ViewBuilder var content: () -> Content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        content()
            .id(currentIndex)
            .transition(
                reduceMotion
                    ? .opacity
                    : AnyTransition.asymmetric(
                        insertion: AnyTransition.opacity
                            .combined(with: .scale(scale: 0.95, anchor: .center))
                            .animation(.spring(response: 0.6, dampingFraction: 0.8)),
                        removal: AnyTransition.opacity
                            .combined(with: .scale(scale: 0.95, anchor: .center))
                            .animation(.spring(response: 0.5, dampingFraction: 0.85))
                    )
            )
    }
}

// MARK: - VerseHeaderPinned (상단 고정 영어 말씀)

struct VerseHeaderPinned: View {
    let verseRef: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "book.closed.fill")
                    .foregroundStyle(DS.Color.gold)
                    .font(.system(size: 14))
                Text(verseRef)
                    .font(DS.Font.caption(.semibold))
                    .foregroundStyle(DS.Color.deepCocoa)
            }

            Text(text)
                .font(DS.Font.verse(17, .regular))
                .foregroundStyle(DS.Color.textPrimary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(DS.Color.canvas)
    }
}

// MARK: - SingleFieldCard (단일 입력 카드)

struct SingleFieldCard: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    private let maxLength = 500

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "pencil")
                    .foregroundStyle(DS.Color.gold)
                Text(title)
                    .font(DS.Font.titleM(.semibold))
                    .foregroundStyle(DS.Color.deepCocoa)

                Spacer()

                // 글자 수 카운터
                Text("\(text.count)/\(maxLength)")
                    .font(DS.Font.caption())
                    .foregroundStyle(text.count > maxLength ? .red : DS.Color.textSecondary)
            }

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(DS.Font.bodyM())
                        .foregroundStyle(DS.Color.placeholder)
                        .padding(.top, 12)
                        .padding(.horizontal, 12)
                }

                TextEditor(text: $text)
                    .font(DS.Font.bodyM())
                    .foregroundStyle(DS.Color.textPrimary)
                    .frame(minHeight: 180)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.s)
                            .fill(DS.Color.canvas)
                    )
                    .onChange(of: text) { newValue in
                        // 500자 제한
                        if newValue.count > maxLength {
                            text = String(newValue.prefix(maxLength))
                        }
                    }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.m)
                .fill(DS.Color.background)
        )
    }
}

// MARK: - ExplanationBubble (말풍선 팝업)

struct ExplanationBubble: View {
    let text: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 헤더 (해설 + X 버튼)
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(DS.Color.gold)
                    Text("해설")
                        .font(DS.Font.caption(.semibold))
                        .foregroundStyle(DS.Color.deepCocoa)
                }

                Spacer()

                // X 버튼
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(DS.Color.textSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("닫기")
            }

            Text(text)
                .font(DS.Font.bodyM())
                .foregroundStyle(DS.Color.textPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(
            ZStack(alignment: .topLeading) {
                // 말풍선 몸통
                RoundedRectangle(cornerRadius: DS.Radius.m)
                    .fill(DS.Color.canvas)
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)

                // 말풍선 꼬리
                Triangle()
                    .fill(DS.Color.canvas)
                    .frame(width: 14, height: 10)
                    .offset(x: 18, y: -5)
                    .shadow(color: .black.opacity(0.05), radius: 2, y: -1)
            }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("해설")
        .accessibilityValue(text)
    }
}

// MARK: - Triangle (말풍선 꼬리)

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
