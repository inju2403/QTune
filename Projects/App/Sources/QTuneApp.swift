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

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
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

    var body: some Scene {
        WindowGroup {
            RootNavigationView { path in
                RequestVerseView(
                    viewModel: RequestVerseViewModel(
                        generateVerseUseCase: GenerateVerseInteractor(
                            repository: DefaultVerseRepository()
                        )
                    ),
                    path: path
                )
            }
            .background(Color(.systemBackground))
        }
    }
}
