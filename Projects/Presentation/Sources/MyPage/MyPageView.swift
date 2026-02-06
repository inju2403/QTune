//
//  MyPageView.swift
//  Presentation
//
//  Created by 이승주 on 1/15/26.
//

import SwiftUI
import Domain

public struct MyPageView: View {
    @State private var viewModel: MyPageViewModel
    @Binding var userProfile: UserProfile?
    @State private var showProfileEdit = false
    @State private var showFontSettings = false
    @Environment(\.openURL) private var openURL

    let profileEditViewModelFactory: (UserProfile?) -> ProfileEditViewModel
    let fontSettingsViewModelFactory: (FontScale, LineSpacing) -> FontSettingsViewModel
    let getUserProfileUseCase: GetUserProfileUseCase
    let saveUserProfileUseCase: SaveUserProfileUseCase

    public init(
        viewModel: MyPageViewModel,
        userProfile: Binding<UserProfile?>,
        profileEditViewModelFactory: @escaping (UserProfile?) -> ProfileEditViewModel,
        fontSettingsViewModelFactory: @escaping (FontScale, LineSpacing) -> FontSettingsViewModel,
        getUserProfileUseCase: GetUserProfileUseCase,
        saveUserProfileUseCase: SaveUserProfileUseCase
    ) {
        _viewModel = State(wrappedValue: viewModel)
        _userProfile = userProfile
        self.profileEditViewModelFactory = profileEditViewModelFactory
        self.fontSettingsViewModelFactory = fontSettingsViewModelFactory
        self.getUserProfileUseCase = getUserProfileUseCase
        self.saveUserProfileUseCase = saveUserProfileUseCase
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                CrossSunsetBackground()

                List {
                    // 프로필 섹션
                    Section {
                        profileHeader()
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                    }

                    // 프로필 수정
                    Section {
                        menuRow(
                            icon: "person.crop.circle",
                            title: "프로필 수정",
                            action: { showProfileEdit = true }
                        )

                        // 역본 선택
                        translationRow()

                        // 폰트 설정
                        fontSettingsRow()
                    }

                    // 큐튠 이야기
                    Section(header: sectionHeader("큐튠 이야기")) {
                        menuRow(
                            icon: "lightbulb",
                            title: "개선점 공유",
                            action: openImprovementForm
                        )
                        menuRow(
                            icon: "hand.thumbsup",
                            title: "칭찬하기",
                            action: openReview
                        )
                    }

                    // 앱 정보
                    Section(header: sectionHeader("앱 정보")) {
                        versionInfoRow()
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("마이페이지")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showProfileEdit, onDismiss: {
                Task {
                    if let profile = try? await getUserProfileUseCase.execute() {
                        await MainActor.run {
                            userProfile = profile
                        }
                    }
                }
            }) {
                NavigationStack {
                    ProfileEditView(
                        viewModel: profileEditViewModelFactory(userProfile)
                    )
                }
            }
            .sheet(isPresented: Binding(
                get: { viewModel.state.showTranslationSelection },
                set: { if !$0 { viewModel.send(.dismissTranslationSelection) } }
            )) {
                DualTranslationSelectionSheet(
                    selectedPrimary: Binding(
                        get: { viewModel.state.selectedPrimaryTranslation },
                        set: { viewModel.send(.selectPrimaryTranslation($0)) }
                    ),
                    selectedSecondary: Binding(
                        get: { viewModel.state.selectedSecondaryTranslation },
                        set: { viewModel.send(.selectSecondaryTranslation($0)) }
                    ),
                    onDone: {
                        if let profile = userProfile {
                            viewModel.send(.saveTranslations(profile))
                        }
                    }
                )
                .presentationDetents([.height(520), .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showFontSettings, onDismiss: {
                Task {
                    if let profile = try? await getUserProfileUseCase.execute() {
                        await MainActor.run {
                            userProfile = profile
                        }
                    }
                }
            }) {
                if let profile = userProfile {
                    FontSettingsView(
                        viewModel: fontSettingsViewModelFactory(
                            profile.fontScale,
                            profile.lineSpacing
                        ),
                        userProfile: $userProfile,
                        onSave: { fontScale, lineSpacing in
                            Task {
                                let updatedProfile = UserProfile(
                                    nickname: profile.nickname,
                                    gender: profile.gender,
                                    profileImageData: profile.profileImageData,
                                    preferredTranslation: profile.preferredTranslation,
                                    secondaryTranslation: profile.secondaryTranslation,
                                    fontScale: fontScale,
                                    lineSpacing: lineSpacing
                                )
                                try? await saveUserProfileUseCase.execute(profile: updatedProfile)
                                await MainActor.run {
                                    userProfile = updatedProfile
                                }
                            }
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Subviews

private extension MyPageView {
    @ViewBuilder
    func profileHeader() -> some View {
        VStack(spacing: 16) {
            // 프로필 이미지
            if let imageData = userProfile?.profileImageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(DS.Color.gold.opacity(0.3), lineWidth: 2)
                    )
            } else {
                Circle()
                    .fill(DS.Color.gold.opacity(0.15))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(DS.Color.gold.opacity(0.5))
                    )
                    .overlay(
                        Circle()
                            .stroke(DS.Color.gold.opacity(0.3), lineWidth: 2)
                    )
            }

            // 이름 + 성별
            if let profile = userProfile {
                Text("\(profile.nickname) \(profile.gender.rawValue)님")
                    .dsTitleL(.bold)
                    .foregroundStyle(DS.Color.deepCocoa)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    @ViewBuilder
    func sectionHeader(_ title: String) -> some View {
        Text(title)
            .dsCaption(.semibold)
            .foregroundStyle(DS.Color.textSecondary)
    }

    @ViewBuilder
    func menuRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            Haptics.tap()
            action()
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(DS.Color.gold)
                    .frame(width: 24)

                Text(title)
                    .dsBodyL()
                    .foregroundStyle(DS.Color.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DS.Color.textSecondary)
            }
        }
    }

    @ViewBuilder
    func fontSettingsRow() -> some View {
        Button(action: {
            Haptics.tap()
            showFontSettings = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "textformat")
                    .font(.system(size: 20))
                    .foregroundStyle(DS.Color.gold)
                    .frame(width: 24)

                Text("폰트 설정")
                    .dsBodyL()
                    .foregroundStyle(DS.Color.textPrimary)

                Spacer()

                HStack(spacing: 4) {
                    Text(userProfile?.fontScale.displayName ?? "보통")
                        .dsCaption()
                        .foregroundStyle(DS.Color.textSecondary)

                    Text("·")
                        .dsCaption()
                        .foregroundStyle(DS.Color.textSecondary)

                    Text(userProfile?.lineSpacing.displayName ?? "보통")
                        .dsCaption()
                        .foregroundStyle(DS.Color.textSecondary)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DS.Color.textSecondary)
            }
        }
    }

    @ViewBuilder
    func translationRow() -> some View {
        Button(action: {
            Haptics.tap()
            // 바텀시트 열기 전 현재 프로필 값으로 State 초기화
            if let profile = userProfile {
                viewModel.send(.selectPrimaryTranslation(profile.preferredTranslation))
                viewModel.send(.selectSecondaryTranslation(profile.secondaryTranslation))
            }
            viewModel.send(.tapTranslationSelection)
        }) {
            HStack(spacing: 12) {
                Image(systemName: "book")
                    .font(.system(size: 20))
                    .foregroundStyle(DS.Color.gold)
                    .frame(width: 24)

                Text("역본")
                    .dsBodyL()
                    .foregroundStyle(DS.Color.textPrimary)

                Spacer()

                HStack(spacing: 4) {
                    Text(userProfile?.preferredTranslation.displayName ?? "개역한글")
                        .dsCaption()
                        .foregroundStyle(DS.Color.textSecondary)

                    if let secondary = userProfile?.secondaryTranslation {
                        Text("·")
                            .dsCaption()
                            .foregroundStyle(DS.Color.textSecondary)

                        Text(secondary.displayName)
                            .dsCaption()
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DS.Color.textSecondary)
            }
        }
    }

    @ViewBuilder
    func versionInfoRow() -> some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle")
                .font(.system(size: 20))
                .foregroundStyle(DS.Color.gold)
                .frame(width: 24)

            Text("버전 정보")
                .dsBodyL()
                .foregroundStyle(DS.Color.textPrimary)

            Spacer()

            Text(appVersion)
                .dsBodyL()
                .foregroundStyle(DS.Color.textSecondary)
                .padding(.trailing, 8)
        }
    }

    func openImprovementForm() {
        guard let url = URL(string: "https://docs.google.com/forms/d/e/1FAIpQLSfzUt_GdAoPGt8ZjGOzsAdtgc6LAK1MPQc2Iu_6izpYB0OlrQ/viewform") else {
            assertionFailure("URL build failed")
            return
        }
        openURL(url)
    }

    func openReview() {
        guard let url = URL(string: "itms-apps://apps.apple.com/kr/app/id6757230938?action=write-review") else {
            assertionFailure("URL build failed")
            return
        }
        openURL(url)
    }

    var appVersion: String {
        // App Bundle에서 버전 정보 읽기
        guard let appBundle = Bundle.allBundles.first(where: { $0.bundleIdentifier == "com.inju.qtune" }),
              let version = appBundle.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return "1.2.1"
        }
        return version
    }
}

// MARK: - Dual Translation Selection Sheet
struct DualTranslationSelectionSheet: View {
    @Binding var selectedPrimary: Translation
    @Binding var selectedSecondary: Translation?
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 타이틀
            VStack(spacing: DS.Spacing.xs) {
                Text("역본 선택")
                    .dsTitleL(.bold)
                    .foregroundStyle(DS.Color.deepCocoa)

                Text("주 역본과 비교 역본을 선택하세요")
                    .dsBodyM()
                    .foregroundStyle(DS.Color.textSecondary)
            }
            .padding(.top, DS.Spacing.xl)
            .padding(.bottom, DS.Spacing.l)

            // 2컬럼 레이아웃
            HStack(alignment: .top, spacing: DS.Spacing.m) {
                // 주 역본 컬럼
                VStack(spacing: DS.Spacing.xs) {
                    Text("주 역본")
                        .dsBodyM(.semibold)
                        .foregroundStyle(DS.Color.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(Translation.allCases, id: \.self) { translation in
                        translationButton(
                            translation: translation,
                            isSelected: translation == selectedPrimary,
                            isDisabled: false,
                            action: { selectedPrimary = translation }
                        )
                    }
                }

                // 비교 역본 컬럼
                VStack(spacing: DS.Spacing.xs) {
                    Text("비교 역본")
                        .dsBodyM(.semibold)
                        .foregroundStyle(DS.Color.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // 선택 안 함 옵션
                    translationButton(
                        translation: nil,
                        isSelected: selectedSecondary == nil,
                        isDisabled: false,
                        action: { selectedSecondary = nil }
                    )

                    // 역본 옵션들 (주 역본 제외)
                    ForEach(Translation.allCases, id: \.self) { translation in
                        if translation != selectedPrimary {
                            translationButton(
                                translation: translation,
                                isSelected: translation == selectedSecondary,
                                isDisabled: false,
                                action: { selectedSecondary = translation }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.l)

            Spacer()

            // 저장 버튼
            Button {
                Haptics.tap()
                onDone()
            } label: {
                Text("저장")
                    .dsBodyL(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Spacing.m)
                    .background(DS.Color.gold)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.m))
            }
            .padding(.horizontal, DS.Spacing.l)
            .padding(.bottom, DS.Spacing.l)
        }
    }

    @ViewBuilder
    func translationButton(
        translation: Translation?,
        isSelected: Bool,
        isDisabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(translation?.displayName ?? "선택 안 함")
                        .dsBodyM(.semibold)
                        .foregroundStyle(
                            isDisabled ? DS.Color.textSecondary.opacity(0.3) :
                            isSelected ? DS.Color.deepCocoa : DS.Color.textPrimary
                        )

                    if let translation = translation {
                        Text(translation.language == "ko" ? "한국어" : "English")
                            .dsCaption()
                            .foregroundStyle(
                                isDisabled ? DS.Color.textSecondary.opacity(0.3) : DS.Color.textSecondary
                            )
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(DS.Color.gold)
                }
            }
            .padding(.horizontal, DS.Spacing.s)
            .padding(.vertical, DS.Spacing.s)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.s)
                    .fill(
                        isDisabled ? DS.Color.canvas.opacity(0.5) :
                        isSelected ? DS.Color.gold.opacity(0.15) : DS.Color.canvas
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.s)
                    .stroke(
                        isDisabled ? DS.Color.textSecondary.opacity(0.1) :
                        isSelected ? DS.Color.gold.opacity(0.3) : DS.Color.textSecondary.opacity(0.1),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}
