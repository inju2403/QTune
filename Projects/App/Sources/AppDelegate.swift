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
import FirebaseMessaging
import FirebaseFirestore
import UserNotifications

/// AppDelegate
///
/// SwiftUI App과 함께 사용하기 위해 @UIApplicationDelegateAdaptor로 주입됩니다.
/// Firebase 초기화를 init()에서 가장 먼저 수행합니다.
class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {

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

        // 앱 실행 시 뱃지 초기화
        application.applicationIconBadgeNumber = 0
        print("🔔 [AppDelegate] Badge cleared on launch")

        // Firebase Anonymous Auth 자동 로그인 먼저 수행
        // Auth 완료 후 FCM 설정하도록 수정
        signInAnonymouslyIfNeeded { [weak self] in
            // Auth 성공 후 FCM 설정 (샌드박스 환경)
            self?.configurePushNotifications(application)
        }

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
    private func signInAnonymouslyIfNeeded(completion: @escaping () -> Void) {
        if let currentUser = Auth.auth().currentUser {
            print("🔐 [AppDelegate] Already signed in anonymously")
            print("   UID: \(currentUser.uid)")
            print("   IsAnonymous: \(currentUser.isAnonymous)")
            // 이미 로그인되어 있으면 바로 completion 호출
            completion()
        } else {
            print("🔐 [AppDelegate] Signing in anonymously...")
            Auth.auth().signInAnonymously { result, error in
                if let error = error {
                    print("🔴 [AppDelegate] Anonymous sign-in failed: \(error.localizedDescription)")
                    // 실패해도 FCM 설정은 시도
                    completion()
                    return
                }

                if let user = result?.user {
                    print("✅ [AppDelegate] Anonymous sign-in successful!")
                    print("   UID: \(user.uid)")
                    print("   IsAnonymous: \(user.isAnonymous)")
                    // 로그인 성공 후 completion 호출
                    completion()
                }
            }
        }
    }

    // MARK: - Push Notification Configuration

    /// FCM 및 푸시 알림 설정
    private func configurePushNotifications(_ application: UIApplication) {
        print("📱 [AppDelegate] Configuring push notifications...")

        // Auth 상태 확인
        if let user = Auth.auth().currentUser {
            print("✅ [AppDelegate] User authenticated before FCM setup: \(user.uid)")
        } else {
            print("⚠️ [AppDelegate] No user authenticated before FCM setup")
        }

        // FCM delegate 설정
        Messaging.messaging().delegate = self

        // UNUserNotificationCenter delegate 설정
        UNUserNotificationCenter.current().delegate = self

        // Auth가 완전히 준비되도록 약간 대기 후 FCM 토큰 요청
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            print("🔍 [FCM] Requesting FCM token after auth delay...")

            // Auth 상태 재확인
            if let user = Auth.auth().currentUser {
                print("✅ [FCM] User confirmed: \(user.uid)")
            }

            Messaging.messaging().token { token, error in
                if let error = error {
                    print("❌ [FCM] Error fetching token: \(error)")
                } else if let token = token {
                    print("🔑 [FCM] Token fetched manually: \(token)")
                    // 수동으로 delegate 메서드 호출
                    self?.messaging(Messaging.messaging(), didReceiveRegistrationToken: token)
                } else {
                    print("⚠️ [FCM] No token returned")
                }
            }
        }

        // 푸시 알림 권한 요청
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            print("📱 [AppDelegate] Push permission granted: \(granted)")
            if let error = error {
                print("⚠️ [AppDelegate] Push permission error: \(error)")
            }

            if granted {
                print("📱 [AppDelegate] Push permission granted, will subscribe to topic after FCM token")
            }
        }

        // APNs 등록
        application.registerForRemoteNotifications()
    }

    // MARK: - MessagingDelegate

    /// FCM 토큰 받았을 때
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("🔑 [FCM] Token received: \(fcmToken ?? "nil")")

        guard let token = fcmToken else {
            print("⚠️ [FCM] No token received")
            return
        }

        guard let uid = Auth.auth().currentUser?.uid else {
            print("⚠️ [FCM] User not authenticated yet, retrying in 2 seconds...")
            // Auth가 아직 안 되었으면 2초 후 재시도
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                if let currentUser = Auth.auth().currentUser {
                    print("🔄 [FCM] Retry: User now authenticated with UID: \(currentUser.uid)")
                    self?.saveFCMTokenToFirestore(token: token, uid: currentUser.uid)
                } else {
                    print("❌ [FCM] Retry failed: Still no authenticated user")
                }
            }
            return
        }

        print("📝 [FCM] User authenticated with UID: \(uid)")
        saveFCMTokenToFirestore(token: token, uid: uid)
    }

    private func saveFCMTokenToFirestore(token: String, uid: String) {
        print("💾 [FCM] Saving token to Firestore for UID: \(uid)")

        // Firestore에 FCM 토큰 저장
        let db = Firestore.firestore()
        let userData: [String: Any] = [
            "fcmToken": token,
            "fcmTokenUpdatedAt": FieldValue.serverTimestamp(),
            "platform": "ios",
            "environment": {
                #if DEBUG
                return "sandbox"
                #else
                return "production"
                #endif
            }()
        ]

        print("📤 [FCM] Saving data: \(userData)")

        db.collection("users").document(uid).setData(userData, merge: true) { error in
            if let error = error {
                print("❌ [FCM] Failed to save token: \(error.localizedDescription)")
            } else {
                print("✅ [FCM] Token saved to Firestore successfully!")
                print("   Path: users/\(uid)")
                print("   Token: \(token)")

                // FCM 토큰 저장 성공 후 Topic 구독
                #if DEBUG
                Messaging.messaging().subscribe(toTopic: "daily_qt_sandbox") { error in
                    if let error = error {
                        print("❌ [FCM] Failed to subscribe to sandbox topic: \(error)")
                    } else {
                        print("✅ [FCM] Subscribed to 'daily_qt_sandbox' topic")
                    }
                }
                #else
                Messaging.messaging().subscribe(toTopic: "daily_qt") { error in
                    if let error = error {
                        print("❌ [FCM] Failed to subscribe to topic: \(error)")
                    } else {
                        print("✅ [FCM] Subscribed to 'daily_qt' topic")
                    }
                }
                #endif
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// 앱이 foreground에 있을 때 푸시 받았을 때
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // iOS 14 이상: banner, iOS 13: alert
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound])
        } else {
            completionHandler([.alert, .sound])
        }
    }

    /// 푸시 알림 탭했을 때
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("📱 [Push] User tapped notification")
        // TODO: 앱 내 특정 화면으로 이동 로직 추가
        completionHandler()
    }

    // MARK: - APNs Token (디버깅용)

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("📱 [APNs] Device token received")
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ [APNs] Failed to register: \(error)")
    }
}
