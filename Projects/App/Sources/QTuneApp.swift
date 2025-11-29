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

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // Firebase 초기화
        FirebaseApp.configure()

        // Configure all windows
        configureAppearance()
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }

    private func configureAppearance() {
        // Global window configuration
        UIWindow.appearance().backgroundColor = .systemBackground
        UIWindow.appearance().tintColor = .systemBlue
    }
}

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func sceneWillEnterForeground(_ scene: UIScene) {
        if let windowScene = scene as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.backgroundColor = .systemBackground
                window.rootViewController?.view.backgroundColor = .systemBackground
            }
        }
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let windowScene = scene as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.backgroundColor = .systemBackground
                window.rootViewController?.view.backgroundColor = .systemBackground
            }
        }
    }
}

@main
struct QTuneApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    /// 의존성 주입 컨테이너
    private let container = AppDependencyContainer()

    /// 온보딩 완료 여부 (UserDefaults에서 동기적으로 읽음)
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if !hasCompletedOnboarding {
                // 온보딩 미완료: 온보딩 화면 표시
                onboardingView
                    .background(DS.Color.background)
            } else {
                // 온보딩 완료: 정상 앱 실행
                mainContent
                    .background(DS.Color.background)
            }
        }
    }

    @ViewBuilder
    private var onboardingView: some View {
        OnboardingViewWrapper(
            saveUserProfileUseCase: container.makeSaveUserProfileUseCase(),
            onComplete: {
                hasCompletedOnboarding = true
            }
        )
    }

    @ViewBuilder
    private var mainContent: some View {
        // Firebase Functions 기반으로 OpenAI 호출
        // OPENAI_API_KEY는 iOS에서 관리하지 않음
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
                session: container.dummySession
            )
        } else {
            // iOS 17 미만 또는 초기화 실패
            Text("앱을 사용할 수 없습니다.")
                .foregroundColor(.red)
        }
    }
}

// MARK: - Helper Wrappers
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
