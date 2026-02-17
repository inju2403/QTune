//
//  MyPageView.swift
//  Presentation
//
//  Created by 이승주 on 1/15/26.
//

import SwiftUI
import Domain
import UserNotifications

public struct MyPageView: View {
    @State private var viewModel: MyPageViewModel
    @Binding var userProfile: UserProfile?
    @State private var showProfileEdit = false
    @State private var showFontSettings = false
    @State private var notificationSheetHeight: CGFloat = 450
    @Environment(\.openURL) private var openURL
    @Environment(\.fontScale) private var fontScale

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

                        // 알림 설정
                        notificationSettingsRow()
                    }

                    // 큐튠 이야기
                    Section(header: sectionHeader("큐튠 이야기")) {
                        improvementMenuRow()
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
            .sheet(isPresented: Binding(
                get: { viewModel.state.showNotificationSettings },
                set: { if !$0 { viewModel.send(.dismissNotificationSettings) } }
            )) {
                NotificationSettingsSheet(
                    isNotificationEnabled: Binding(
                        get: { viewModel.state.isNotificationEnabled },
                        set: { viewModel.send(.toggleNotification($0)) }
                    ),
                    notificationTime: Binding(
                        get: { viewModel.state.notificationTime },
                        set: { viewModel.send(.selectNotificationTime($0)) }
                    ),
                    onSave: {
                        if let profile = userProfile {
                            viewModel.send(.saveNotificationSettings(profile))
                        }
                    },
                    sheetHeight: $notificationSheetHeight
                )
                .presentationDetents([.height(notificationSheetHeight)])
                .presentationDragIndicator(.visible)
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
                DSText.titleL("\(profile.nickname) \(profile.gender.rawValue)님", weight: .bold)
                    .foregroundStyle(DS.Color.deepCocoa)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    @ViewBuilder
    func sectionHeader(_ title: String) -> some View {
        DSText.caption(title, weight: .semibold)
            .foregroundStyle(DS.Color.textSecondary)
    }

    @ViewBuilder
    func improvementMenuRow() -> some View {
        Button(action: {
            Haptics.tap()
            openKakaoChannel()
        }) {
            HStack(spacing: 12) {
                Image(systemName: "text.bubble")
                    .font(.system(size: 20))
                    .foregroundStyle(DS.Color.gold)
                    .frame(width: 24)

                DSText.bodyL("의견 보내기")
                    .foregroundStyle(DS.Color.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DS.Color.textSecondary)
            }
        }
    }

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

                DSText.bodyL(title)
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

                DSText.bodyL("폰트 설정")
                    .foregroundStyle(DS.Color.textPrimary)

                Spacer()

                HStack(spacing: 4) {
                    DSText.caption(userProfile?.fontScale.displayName ?? "보통")
                        .foregroundStyle(DS.Color.textSecondary)

                    DSText.caption("·")
                        .foregroundStyle(DS.Color.textSecondary)

                    DSText.caption(userProfile?.lineSpacing.displayName ?? "보통")
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

                DSText.bodyL("역본")
                    .foregroundStyle(DS.Color.textPrimary)

                Spacer()

                HStack(spacing: 4) {
                    DSText.caption(userProfile?.preferredTranslation.displayName ?? "개역한글")
                        .foregroundStyle(DS.Color.textSecondary)

                    if let secondary = userProfile?.secondaryTranslation {
                        DSText.caption("·")
                            .foregroundStyle(DS.Color.textSecondary)

                        DSText.caption(secondary.displayName)
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
    func notificationSettingsRow() -> some View {
        Button(action: {
            Haptics.tap()
            // Initialize state with current profile values before opening sheet
            if let profile = userProfile {
                var components = DateComponents()
                components.hour = profile.notificationHour
                components.minute = profile.notificationMinute
                let notificationTime = Calendar.current.date(from: components) ?? Date()
                viewModel.send(.selectNotificationTime(notificationTime))
                viewModel.send(.toggleNotification(profile.isNotificationEnabled))
            }
            viewModel.send(.tapNotificationSettings)
        }) {
            HStack(spacing: 12) {
                Image(systemName: "bell")
                    .font(.system(size: 20))
                    .foregroundStyle(DS.Color.gold)
                    .frame(width: 24)

                Text("알림 설정")
                    .dsBodyL()
                    .foregroundStyle(DS.Color.textPrimary)

                Spacer()

                NotificationStatusText(userProfile: userProfile)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DS.Color.textSecondary)
            }
        }
    }

    private func formatNotificationTime(hour: Int, minute: Int) -> String {
        let period = hour < 12 ? "오전" : "오후"
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return String(format: "%@ %d:%02d", period, displayHour, minute)
    }

    @ViewBuilder
    func versionInfoRow() -> some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle")
                .font(.system(size: 20))
                .foregroundStyle(DS.Color.gold)
                .frame(width: 24)

            DSText.bodyL("버전 정보")
                .foregroundStyle(DS.Color.textPrimary)

            Spacer()

            DSText.bodyL(appVersion)
                .foregroundStyle(DS.Color.textSecondary)
                .padding(.trailing, 8)
        }
    }

    func openKakaoChannel() {
        // 카카오톡 채널 채팅 직접 연결
        guard let url = URL(string: "https://pf.kakao.com/_xiqLzX/chat") else {
            assertionFailure("URL build failed")
            return
        }
        openURL(url)
    }

    func openGoogleForm() {
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
        // 현재 실행 중인 앱의 Bundle에서 버전 정보 읽기
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return "버전 정보 없음"
        }
        return version
    }
}

// MARK: - Notification Status Text
struct NotificationStatusText: View {
    let userProfile: UserProfile?
    @State private var systemNotificationEnabled = true
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        HStack(spacing: 4) {
            if systemNotificationEnabled, let profile = userProfile, profile.isNotificationEnabled {
                Text(formatNotificationTime(hour: profile.notificationHour, minute: profile.notificationMinute))
                    .dsCaption()
                    .foregroundStyle(DS.Color.textSecondary)
            } else {
                Text("꺼짐")
                    .dsCaption()
                    .foregroundStyle(DS.Color.textSecondary)
            }
        }
        .onAppear {
            checkSystemNotificationSettings()
        }
        .onChange(of: scenePhase) { _, newPhase in
            // 앱이 포그라운드로 돌아올 때 시스템 알림 상태 재확인
            if newPhase == .active {
                checkSystemNotificationSettings()
            }
        }
    }

    private func checkSystemNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                systemNotificationEnabled = settings.authorizationStatus == .authorized
            }
        }
    }

    private func formatNotificationTime(hour: Int, minute: Int) -> String {
        let period = hour < 12 ? "오전" : "오후"
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return String(format: "%@ %d:%02d", period, displayHour, minute)
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
                DSText.titleL("역본 선택", weight: .bold)
                    .foregroundStyle(DS.Color.deepCocoa)

                DSText.bodyM("주 역본과 비교 역본을 선택하세요")
                    .foregroundStyle(DS.Color.textSecondary)
            }
            .padding(.top, DS.Spacing.xl)
            .padding(.bottom, DS.Spacing.l)

            // 2컬럼 레이아웃
            HStack(alignment: .top, spacing: DS.Spacing.m) {
                // 주 역본 컬럼
                VStack(spacing: DS.Spacing.xs) {
                    DSText.bodyM("주 역본", weight: .semibold)
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
                    DSText.bodyM("비교 역본", weight: .semibold)
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
                DSText.bodyL("저장", weight: .semibold)
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
                    DSText.bodyM(translation?.displayName ?? "선택 안 함", weight: .semibold)
                        .foregroundStyle(
                            isDisabled ? DS.Color.textSecondary.opacity(0.3) :
                            isSelected ? DS.Color.deepCocoa : DS.Color.textPrimary
                        )

                    if let translation = translation {
                        DSText.caption(translation.language == "ko" ? "한국어" : "English")
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

// MARK: - Notification Settings Sheet
struct NotificationSettingsSheet: View {
    @Binding var isNotificationEnabled: Bool
    @Binding var notificationTime: Date
    let onSave: () -> Void
    @Binding var sheetHeight: CGFloat

    @Environment(\.fontScale) private var fontScale
    @Environment(\.scenePhase) private var scenePhase
    @State private var systemNotificationEnabled = true
    @State private var showSystemSettingsAlert = false

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Title
                VStack(spacing: DS.Spacing.xs) {
                    Text("알림 설정")
                        .dsTitleL(.bold)
                        .foregroundStyle(DS.Color.deepCocoa)

                    Text("매일 QT 시간을 알려드릴게요")
                        .dsBodyM()
                        .foregroundStyle(DS.Color.textSecondary)
                }
                .padding(.top, DS.Spacing.xl)
                .padding(.bottom, DS.Spacing.l)

                // Toggle
                HStack {
                    Text("알림 받기")
                        .dsBodyL(.semibold)
                        .foregroundStyle(DS.Color.textPrimary)

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { systemNotificationEnabled && isNotificationEnabled },
                        set: { newValue in
                            if !systemNotificationEnabled {
                                // 시스템 알림이 꺼져있으면 설정으로 바로 이동
                                openSystemSettings()
                            } else {
                                isNotificationEnabled = newValue
                            }
                        }
                    ))
                    .toggleStyle(SwitchToggleStyle(tint: DS.Color.gold))
                }
                .padding(.horizontal, DS.Spacing.l)
                .padding(.vertical, DS.Spacing.m)
                .background(DS.Color.canvas)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.m))
                .padding(.horizontal, DS.Spacing.l)

                // 시스템 알림 꺼져있을 때 안내 메시지
                if !systemNotificationEnabled {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(DS.Color.gold)

                        Text("iPhone 설정에서 알림을 활성화해주세요")
                            .dsCaption()
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                    .padding(.horizontal, DS.Spacing.l)
                    .padding(.top, DS.Spacing.xs)
                }

                if isNotificationEnabled {
                    // Time Picker
                    VStack(spacing: DS.Spacing.s) {
                        HStack {
                            Text("알림 시간")
                                .dsBodyM(.semibold)
                                .foregroundStyle(DS.Color.textPrimary)

                            Spacer()
                        }

                        DatePicker(
                            "",
                            selection: $notificationTime,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
                        .environment(\.locale, Locale(identifier: "ko_KR"))
                    }
                    .padding(.horizontal, DS.Spacing.l)
                    .padding(.top, DS.Spacing.m)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Spacer()

                // Save Button
                Button {
                    Haptics.tap()
                    onSave()
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
            .onAppear {
                calculateHeight()
                checkSystemNotificationSettings()
            }
            .onChange(of: isNotificationEnabled) { _, _ in
                withAnimation(.easeInOut(duration: 0.2)) {
                    calculateHeight()
                }
            }
            .onChange(of: fontScale) { _, _ in
                calculateHeight()
            }
            .onChange(of: scenePhase) { _, newPhase in
                // 앱이 포그라운드로 돌아올 때 시스템 알림 상태 재확인
                if newPhase == .active {
                    checkSystemNotificationSettings()
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isNotificationEnabled)
        .alert("알림 권한이 필요합니다", isPresented: $showSystemSettingsAlert) {
            Button("취소", role: .cancel) { }
            Button("설정으로 이동") {
                openSystemSettings()
            }
        } message: {
            Text("iPhone 설정에서 큐튠 알림을 활성화해주세요")
        }
    }

    private func calculateHeight() {
        // Base height calculation
        let multiplier = fontScale.multiplier
        let titleHeight = 28 * multiplier + 20 * multiplier + DS.Spacing.xs + DS.Spacing.xl + DS.Spacing.l
        let toggleHeight = 24 * multiplier + DS.Spacing.m * 2
        let buttonHeight = 24 * multiplier + DS.Spacing.m * 2 + DS.Spacing.l

        var totalHeight = titleHeight + toggleHeight + buttonHeight + DS.Spacing.l

        // Add time picker height if enabled
        if isNotificationEnabled {
            let timePickerHeight: CGFloat = 216 + DS.Spacing.s + 20 * multiplier + DS.Spacing.m
            totalHeight += timePickerHeight
        }

        // Add some padding for safety
        totalHeight += 40

        // Ensure minimum height and cap at max height
        sheetHeight = min(max(totalHeight, 350), UIScreen.main.bounds.height * 0.8)
    }

    private func checkSystemNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                let wasSystemEnabled = systemNotificationEnabled
                systemNotificationEnabled = settings.authorizationStatus == .authorized

                // 시스템 알림이 꺼져있으면 앱 내 설정도 끄기
                if !systemNotificationEnabled {
                    isNotificationEnabled = false
                }
                // 시스템 알림이 방금 켜졌고 앱 내 설정이 꺼져있으면 앱 내 설정도 자동으로 켜기
                else if !wasSystemEnabled && systemNotificationEnabled && !isNotificationEnabled {
                    isNotificationEnabled = true
                }
            }
        }
    }

    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
