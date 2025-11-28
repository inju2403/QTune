//
//  RequestVerseView.swift
//  QTune
//
//  Created by 이승주 on 7/26/25.
//

import SwiftUI
import Domain

public struct RequestVerseView: View {
    // MARK: - State
    @State private var viewModel: RequestVerseViewModel
    @State private var showConflict = false
    @State private var resultPhase: ResultPhase = .idle
    @State private var userProfile: UserProfile?
    @State private var showProfileEdit = false
    @Binding var path: NavigationPath
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Dependencies
    let commitQTUseCase: CommitQTUseCase
    let session: UserSession
    let getUserProfileUseCase: GetUserProfileUseCase
    let saveUserProfileUseCase: SaveUserProfileUseCase
    let onNavigateToRecordTab: () -> Void

    // MARK: - Init
    public init(
        viewModel: RequestVerseViewModel,
        path: Binding<NavigationPath>,
        commitQTUseCase: CommitQTUseCase,
        session: UserSession,
        getUserProfileUseCase: GetUserProfileUseCase,
        saveUserProfileUseCase: SaveUserProfileUseCase,
        onNavigateToRecordTab: @escaping () -> Void
    ) {
        _viewModel = State(wrappedValue: viewModel)
        _path = path
        self.commitQTUseCase = commitQTUseCase
        self.session = session
        self.getUserProfileUseCase = getUserProfileUseCase
        self.saveUserProfileUseCase = saveUserProfileUseCase
        self.onNavigateToRecordTab = onNavigateToRecordTab
    }

    // MARK: - Body
    public var body: some View {
        ZStack {
            CrossSunsetBackground()

            VStack(spacing: 0) {
                // 앱 아이콘 영역
                Image("QTune_Icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
                    .padding(.top, 8)
                    .padding(.bottom, 24)

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        draftBanner()
                        descriptionSection()
                        inputSection()
                        errorSection()

                    // CTA 버튼
                    Button {
                        Haptics.tap()
                        Task {
                            resultPhase = .loading
                            viewModel.send(.tapRequest)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16))
                            Text("오늘의 말씀 추천받기")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(hex: "#8B7355"))
                        )
                        .shadow(color: Color.black.opacity(0.08), radius: 8, y: 3)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 60)
                    }
                    .padding(.horizontal, 22)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ProfileHeaderView(profile: userProfile) {
                        Haptics.tap()
                        showProfileEdit = true
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)

            // Loading overlay
            if resultPhase == .loading {
                QTuneCrossOverlay()
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .onAppear {
            viewModel.send(.onAppear(userId: "me"))
            loadUserProfile()
        }
        .onReceive(viewModel.effect) { eff in
            switch eff {
            case .showError:
                resultPhase = .idle
            case .presentDraftConflict:
                showConflict = true
            case .navigateToEditor(let draft):
                path.append(draft)
            case .navigateToQTEditor, .showToast:
                break
            }
        }
        .onChange(of: viewModel.state.generatedResult) { newValue in
            if let result = newValue {
                // Haptic 피드백
                Haptics.success()

                // 로딩 UI 닫기
                withAnimation(.easeInOut(duration: 0.25)) {
                    resultPhase = .idle
                }

                // ResultView로 네비게이션
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    path.append(QTRoute.result(result))
                }
            } else if resultPhase != .loading {
                resultPhase = .idle
            }
        }
        .navigationDestination(for: QTRoute.self) { route in
            Group {
                switch route {
                case .result(let result):
                    buildResultView(result: result)
                case .editor(let template, let verseEN, let verseRef, let explKR, let verse):
                    buildEditorWizardView(
                        template: template,
                        verseEN: verseEN,
                        verseRef: verseRef,
                        explKR: explKR,
                        verse: verse
                    )
                }
            }
        }
        .confirmationDialog("작성 중인 QT가 있어요",
                            isPresented: $showConflict,
                            titleVisibility: .visible) {
            Button("이어쓰기") { viewModel.send(.tapResumeDraft) }
            Button("새로 시작", role: .destructive) {
                viewModel.send(.tapDiscardDraft)
                viewModel.send(.tapRequest)
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("새로 시작하면 기존 초안은 삭제돼요. 어떻게 할까요?")
        }
        .sheet(isPresented: $showProfileEdit) {
            profileEditSheet()
        }
    }
}

// MARK: - Subviews
private extension RequestVerseView {
    @ViewBuilder
    func draftBanner() -> some View {
        if viewModel.state.showDraftBanner {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .foregroundStyle(DSColor.gold)
                        .font(.system(size: 20))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("오늘 작성 중인 QT가 있어요")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.95))
                        Text("이어 쓰거나 삭제할 수 있어요")
                            .font(.system(size: 14))
                            .foregroundStyle(DSColor.textSec)
                    }
                    Spacer()
                }

                HStack(spacing: 12) {
                    Button("이어쓰기") {
                        Haptics.tap()
                        viewModel.send(.tapResumeDraft)
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(DSColor.accent)

                    Button("삭제") {
                        Haptics.tap()
                        viewModel.send(.tapDiscardDraft)
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(DSColor.textSec)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(DSColor.card.opacity(0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
        }
    }

    func descriptionSection() -> some View {
        VStack(alignment: .center, spacing: 16) {
            if let profile = userProfile {
                // 개인화된 인사말 (큰 Serif 헤드라인)
                VStack(spacing: 12) {
                    Text("\(profile.nickname) \(profile.gender.rawValue)님")
                        .font(.system(size: 36, weight: .bold, design: .serif))
                        .foregroundStyle(DS.Color.deepCocoa)

                    // 부제 (SF Rounded Light)
                    Text("오늘 어떤 일이 있으셨나요?")
                        .font(.system(size: 18, weight: .light, design: .rounded))
                        .foregroundStyle(DS.Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)

                    Text("글로 알려주시면 \(profile.nickname) \(profile.gender.rawValue)님에게\n오늘의 말씀을 추천해드릴게요")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(DS.Color.textSecondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                }
            } else {
                // 프로필 로드 전 기본 텍스트
                VStack(spacing: 12) {
                    Text("오늘의 말씀")
                        .font(.system(size: 36, weight: .bold, design: .serif))
                        .foregroundStyle(DS.Color.deepCocoa)

                    Text("오늘의 생각, 감정, 상황을\n자유롭게 적어보세요")
                        .font(.system(size: 18, weight: .light, design: .rounded))
                        .foregroundStyle(DS.Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    func inputSection() -> some View {
        // 단일 통합 입력 필드
        VStack(alignment: .leading, spacing: 18) {
            // 제목
            Text("어떤 내용이든 좋아요.\n오늘 느낀 감정, 생각 등을 공유해주세요.")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: "#6B6B6B"))
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
                .padding(.bottom, 4)

            // 입력 영역
            unifiedInputArea()

            // 글자 수
            HStack {
                Spacer()
                Text("\(viewModel.state.moodText.count)/700")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(viewModel.state.moodText.count > 700 ? Color.red.opacity(0.7) : Color(hex: "#AFAFAF"))
            }
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(DS.Color.canvas.opacity(0.9))
        )
    }

    func unifiedInputArea() -> some View {
        let binding = Binding<String>(
            get: { viewModel.state.moodText },
            set: { newValue in
                // 700자 제한
                let limited = String(newValue.prefix(700))
                viewModel.send(.updateMood(limited))
            }
        )

        return ZStack(alignment: .topLeading) {
            if viewModel.state.moodText.isEmpty {
                Text("내용을 입력하세요...")
                    .font(.system(size: 16, design: .rounded))
                    .foregroundStyle(Color(hex: "#D4D4D4"))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
            }

            TextEditor(text: binding)
                .font(.system(size: 16, design: .rounded))
                .foregroundStyle(Color(hex: "#3A3A3A"))
                .frame(minHeight: 160)
                .scrollContentBackground(.hidden)
                .textInputAutocapitalization(.sentences)
                .disableAutocorrection(false)
        }
        .padding(12)
        .background(Color(hex: "#F8F8F8"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    func errorSection() -> some View {
        if let errorMessage = viewModel.state.errorMessage {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)

                Text(errorMessage)
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.95))

                Spacer()

                Button {
                    Haptics.tap()
                    viewModel.send(.dismissError)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(DSColor.textSec)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.orange.opacity(0.2))
            )
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    @ViewBuilder
    func skeleton() -> some View {
        VStack(spacing: 14) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 22)
                    .fill(DSColor.card.opacity(0.7))
                    .frame(height: 140)
                    .redacted(reason: .placeholder)
                    .shimmer()
            }
        }
    }

    @ViewBuilder
    func resultContent(result: GeneratedVerseResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(icon: "checkmark.circle.fill", title: "추천 말씀")

            ExpandableCard(title: result.verse.id, delay: 0.00) {
                Text(result.verse.text)
                    .lineSpacing(4)
            }

            if !result.korean.isEmpty {
                ExpandableCard(title: "해설", delay: 0.06) {
                    let lines = result.korean.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
                    if lines.count == 2 {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(String(lines[0]))
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(DSColor.gold)

                            Text(String(lines[1]))
                                .lineSpacing(4)
                        }
                    } else {
                        Text(result.korean)
                            .lineSpacing(4)
                    }
                }
            }

            if !result.rationale.isEmpty {
                ExpandableCard(title: "추천 이유", delay: 0.12) {
                    Text(result.rationale)
                        .lineSpacing(4)
                }
            }

            PrimaryCTAButton(title: "QT 하러 가기", icon: "hand.raised.fill") {
                viewModel.send(.tapGoToQT)
            }
            .padding(.top, 4)
        }
    }

    @ViewBuilder
    func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(DSColor.gold)
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white.opacity(0.95))
            Spacer()
        }
        .padding(.top, 6)
    }

    private func loadUserProfile() {
        Task {
            do {
                let profile = try await getUserProfileUseCase.execute()
                await MainActor.run {
                    userProfile = profile
                }
            } catch {
                print("Failed to load user profile: \(error)")
            }
        }
    }

    @ViewBuilder
    private func profileEditSheet() -> some View {
        NavigationStack {
            ProfileEditViewWrapper(
                userProfile: userProfile,
                saveUserProfileUseCase: saveUserProfileUseCase,
                onSaveComplete: {
                    loadUserProfile()
                    showProfileEdit = false
                }
            )
        }
    }

    @ViewBuilder
    private func buildResultView(result: GeneratedVerseResult) -> some View {
        ResultViewWrapper(
            result: result,
            path: $path
        )
    }

    @ViewBuilder
    private func buildEditorWizardView(
        template: TemplateKind,
        verseEN: String,
        verseRef: String,
        explKR: String,
        verse: Verse
    ) -> some View {
        QTEditorWizardViewWrapper(
            template: template,
            verseEN: verseEN,
            verseRef: verseRef,
            explKR: explKR,
            verse: verse,
            commitQTUseCase: commitQTUseCase,
            session: session,
            onSaveComplete: {
                // 네비게이션 스택 초기화
                self.path = NavigationPath()
                // 기록 탭으로 전환
                self.onNavigateToRecordTab()
            }
        )
    }
}

// MARK: - Helper Views

struct ProfileEditViewWrapper: View {
    let userProfile: UserProfile?
    let saveUserProfileUseCase: SaveUserProfileUseCase
    let onSaveComplete: () -> Void

    var body: some View {
        let profileVM = ProfileEditViewModel(
            currentProfile: userProfile,
            saveUserProfileUseCase: saveUserProfileUseCase
        )
        profileVM.onSaveComplete = onSaveComplete
        return ProfileEditView(viewModel: profileVM)
    }
}

struct ResultViewWrapper: View {
    let result: GeneratedVerseResult
    @Binding var path: NavigationPath

    var body: some View {
        let resultState = ResultState(result: result)
        let resultViewModel = ResultViewModel(initialState: resultState)
        resultViewModel.onNavigateToEditor = { template in
            let editorRoute = QTRoute.editor(
                template: template,
                verseEN: result.verse.text,
                verseRef: result.verseRef,
                explKR: result.korean,
                verse: result.verse
            )
            path.append(editorRoute)
        }
        return ResultView(viewModel: resultViewModel)
    }
}

struct QTEditorWizardViewWrapper: View {
    let template: TemplateKind
    let verseEN: String
    let verseRef: String
    let explKR: String
    let verse: Verse
    let commitQTUseCase: CommitQTUseCase
    let session: UserSession
    let onSaveComplete: () -> Void

    var body: some View {
        let initialState = QTEditorWizardState(
            template: template,
            verseEN: verseEN,
            verseRef: verseRef,
            explKR: explKR,
            verse: verse
        )
        let wizardViewModel = QTEditorWizardViewModel(
            commitQTUseCase: commitQTUseCase,
            session: session,
            initialState: initialState
        )
        wizardViewModel.onSaveComplete = onSaveComplete
        return QTEditorWizardView(viewModel: wizardViewModel)
    }
}
