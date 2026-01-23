//
//  AppDelegate.swift
//  App
//
//  Created by 이승주 on 11/29/25.
//

import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseCrashlytics
import FirebaseAnalytics

/// AppDelegate
///
/// SwiftUI App과 함께 사용하기 위해 @UIApplicationDelegateAdaptor로 주입됩니다.
/// Firebase 초기화를 init()에서 가장 먼저 수행합니다.
class AppDelegate: NSObject, UIApplicationDelegate {

    override init() {
        // AppDelegate 생성 시점에 Firebase 초기화
        // 이 시점이 가장 빠름 (QTuneApp property 초기화보다 먼저)
        super.init()

        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("🔥 [AppDelegate.init] Firebase configured")

            // Crashlytics 초기화 (자동 크래시 리포팅 활성화)
            #if DEBUG
            print("🐛 [AppDelegate.init] Crashlytics enabled (DEBUG mode)")
            #else
            print("📊 [AppDelegate.init] Crashlytics enabled (RELEASE mode)")
            #endif

            // Analytics 강제 호출은 didFinishLaunching (Auth 초기화 이후에 호출해야 안전)
        }
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        print("🔥 [AppDelegate] Application did finish launching")

        // Firebase Anonymous Auth 자동 로그인 먼저 수행
        signInAnonymouslyIfNeeded()

        // Analytics 강제 호출
        // Auth 초기화 이후에 호출하여 안전하게 링커에 포함
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            Analytics.logEvent(AnalyticsEventAppOpen, parameters: nil)
            print("📈 [AppDelegate] Forced Analytics AppOpen Event")
        }

        return true
    }

    /// Firebase Anonymous Auth 자동 로그인
    ///
    /// 이미 로그인되어 있으면 스킵하고, 아니면 익명 로그인을 수행합니다.
    /// 재설치 시에도 자동으로 새 익명 계정을 생성합니다.
    private func signInAnonymouslyIfNeeded() {
        if let currentUser = Auth.auth().currentUser {
            print("🔐 [AppDelegate] Already signed in anonymously")
            print("   UID: \(currentUser.uid)")
            print("   IsAnonymous: \(currentUser.isAnonymous)")
        } else {
            print("🔐 [AppDelegate] Signing in anonymously...")
            Auth.auth().signInAnonymously { result, error in
                if let error = error {
                    print("🔴 [AppDelegate] Anonymous sign-in failed: \(error.localizedDescription)")
                    return
                }

                if let user = result?.user {
                    print("✅ [AppDelegate] Anonymous sign-in successful!")
                    print("   UID: \(user.uid)")
                    print("   IsAnonymous: \(user.isAnonymous)")
                }
            }
        }
    }
}
