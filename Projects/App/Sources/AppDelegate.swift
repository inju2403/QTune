//
//  AppDelegate.swift
//  App
//
//  Created by 이승주 on 11/29/25.
//

import UIKit
import FirebaseAuth

/// AppDelegate
///
/// SwiftUI App과 함께 사용하기 위해 @UIApplicationDelegateAdaptor로 주입됩니다.
/// Firebase 초기화는 QTuneApp.init()에서 수행됩니다.
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Firebase는 QTuneApp.init()에서 이미 초기화됨
        print("🔥 [AppDelegate] Application did finish launching")

        // Firebase Anonymous Auth 자동 로그인
        signInAnonymouslyIfNeeded()

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
