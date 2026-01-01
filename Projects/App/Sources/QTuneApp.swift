//
//  QTuneApp.swift
//  QTune
//
//  Created by 이승주 on 7/26/25.
//

import SwiftUI
import Presentation
import Domain
import Data
import FirebaseCore
import FirebaseAuth

@main
struct QTuneApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var isAuthReady = false
    @State private var isProfileLoaded = false
    @State private var userProfile: UserProfile?

    // Singleton container (init() 이후 첫 접근 시 lazy 초기화)
    private let container = AppDependencyContainer.shared

    init() {
        // Firebase를 가장 먼저 초기화
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("🔥 [QTuneApp.init] Firebase configured")
        }

        // 전역 appearance 설정
        UIWindow.appearance().backgroundColor = .systemBackground
        UIWindow.appearance().tintColor = .systemBlue
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                // 메인 콘텐츠 (항상 렌더링, 뒤에 위치)
                if !hasCompletedOnboarding {
                    onboardingView
                        .background(DS.Color.background)
                } else {
                    mainContent
                        .background(DS.Color.background)
                }

                // 스플래시 화면 (위에 오버레이, 로딩 완료 시 페이드아웃)
                if !isAuthReady || !isProfileLoaded {
                    LaunchScreenView()
                        .task {
                            await checkAuthAndProfile()
                        }
                        .zIndex(1)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: isAuthReady)
            .animation(.easeInOut(duration: 0.5), value: isProfileLoaded)
            .animation(.easeInOut(duration: 0.5), value: hasCompletedOnboarding)
        }
    }

    @MainActor
    private func checkAuthAndProfile() async {
        // 스플래시 시작 시간 기록
        let startTime = Date()

        // 1. Auth 체크
        if Auth.auth().currentUser == nil {
            // AppDelegate의 익명 로그인이 완료될 때까지 대기 (최대 5초)
            for _ in 0..<50 {
                if Auth.auth().currentUser != nil {
                    print("✅ [QTuneApp] Auth ready, UID: \(Auth.auth().currentUser!.uid)")
                    break
                }
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            }

            if Auth.auth().currentUser == nil {
                print("🔴 [QTuneApp] Auth timeout - Anonymous sign-in failed")
            }
        } else {
            print("✅ [QTuneApp] Already authenticated, UID: \(Auth.auth().currentUser!.uid)")
        }

        // 2. Profile 로드
        do {
            if let profile = try await container.makeGetUserProfileUseCase().execute() {
                userProfile = profile
                print("✅ [QTuneApp] Profile loaded: \(profile.nickname)")
            }
        } catch {
            print("⚠️ [QTuneApp] Failed to load user profile: \(error)")
            // 프로필 로드 실패해도 진행 (기본값 사용)
        }

        // 3. 최소 스플래시 시간 보장
        await ensureMinimumSplashDuration(startTime: startTime)

        // 4. 화면 전환
        isAuthReady = true
        isProfileLoaded = true
    }

    /// 최소 1.5초 스플래시 화면 보장
    @MainActor
    private func ensureMinimumSplashDuration(startTime: Date) async {
        let minimumDuration: TimeInterval = 1.5
        let elapsed = Date().timeIntervalSince(startTime)
        let remaining = minimumDuration - elapsed

        if remaining > 0 {
            try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
        }
    }

    @ViewBuilder
    private var onboardingView: some View {
        OnboardingViewWrapper(
            saveUserProfileUseCase: container.makeSaveUserProfileUseCase(),
            onComplete: {
                hasCompletedOnboarding = true
                // 온보딩 완료 후 프로필 로드
                Task {
                    do {
                        if let profile = try await container.makeGetUserProfileUseCase().execute() {
                            await MainActor.run {
                                userProfile = profile
                                print("✅ [QTuneApp] Profile loaded after onboarding: \(profile.nickname)")
                            }
                        }
                    } catch {
                        print("⚠️ [QTuneApp] Failed to load profile after onboarding: \(error)")
                    }
                }
            }
        )
    }

    @ViewBuilder
    private var mainContent: some View {
        if #available(iOS 17, *),
           let commitQTUseCase = container.makeCommitQTUseCase(),
           let updateQTUseCase = container.makeUpdateQTUseCase(),
           let deleteQTUseCase = container.makeDeleteQTUseCase(),
           let fetchQTListUseCase = container.makeFetchQTListUseCase(),
           let toggleFavoriteUseCase = container.makeToggleFavoriteUseCase() {

            let generateVerseUseCase = container.makeGenerateVerseUseCase()

            let qtListVM = QTListViewModel(
                fetchQTListUseCase: fetchQTListUseCase,
                toggleFavoriteUseCase: toggleFavoriteUseCase,
                deleteQTUseCase: deleteQTUseCase,
                session: container.dummySession
            )

            MainTabViewWrapper(
                qtListViewModel: qtListVM,
                detailViewModelFactory: { qt in
                    QTDetailViewModel(
                        qt: qt,
                        toggleFavoriteUseCase: toggleFavoriteUseCase,
                        deleteQTUseCase: deleteQTUseCase,
                        session: container.dummySession
                    )
                },
                editorViewModelFactory: {
                    QTEditorViewModel(
                        commitQTUseCase: commitQTUseCase,
                        updateQTUseCase: updateQTUseCase,
                        session: container.dummySession
                    )
                },
                profileEditViewModelFactory: { currentProfile in
                    ProfileEditViewModel(
                        currentProfile: currentProfile,
                        saveUserProfileUseCase: container.makeSaveUserProfileUseCase()
                    )
                },
                generateVerseUseCase: generateVerseUseCase,
                commitQTUseCase: commitQTUseCase,
                getUserProfileUseCase: container.makeGetUserProfileUseCase(),
                saveUserProfileUseCase: container.makeSaveUserProfileUseCase(),
                session: container.dummySession,
                userProfile: $userProfile
            )
        } else {
            Text("앱을 사용할 수 없습니다.")
                .foregroundColor(.red)
        }
    }
}

// MARK: - Helper Wrappers

/// LaunchScreen과 동일한 디자인의 로딩 화면
struct LaunchScreenView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // QTune_Splash 배경 이미지 (전체 화면, scaleAspectFill)
                Image("QTune_Splash")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .ignoresSafeArea()

                // 하단 텍스트 - LaunchScreen과 정확히 동일한 위치
                VStack(spacing: 8) {
                    Text("주의 말씀은 내 발에 등이요")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(red: 0.51, green: 0.40, blue: 0.33).opacity(0.9))
                        .multilineTextAlignment(.center)

                    Text("Your word is a lamp to my feet. (Ps 119:105)")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.51, green: 0.40, blue: 0.33).opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 32)
                .padding(.bottom, 120) // view의 bottom에서 120pt (SafeArea 무시)
                .ignoresSafeArea(.all, edges: .bottom) // bottom SafeArea 무시
            }
        }
        .ignoresSafeArea()
    }
}

struct OnboardingViewWrapper: View {
    let saveUserProfileUseCase: SaveUserProfileUseCase
    let onComplete: () -> Void

    var body: some View {
        let onboardingVM = OnboardingViewModel(
            saveUserProfileUseCase: saveUserProfileUseCase
        )
        onboardingVM.onComplete = onComplete
        return OnboardingView(viewModel: onboardingVM)
    }
}
