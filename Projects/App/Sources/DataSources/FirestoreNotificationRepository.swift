//
//  FirestoreNotificationRepository.swift
//  App
//
//  Created by 이승주 on 2/14/26.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Firestore에 알림 설정을 저장하는 Repository
///
/// Clean Architecture 원칙상 Data 모듈에서는 Firebase를 직접 import할 수 없으므로
/// App 레이어에서 Firestore 저장 로직을 분리하여 구현
final class FirestoreNotificationRepository {

    private let db = Firestore.firestore()

    /// 알림 설정을 Firestore에 저장
    ///
    /// - Parameters:
    ///   - isEnabled: 알림 활성화 여부
    ///   - hour: 알림 시간 (시)
    ///   - minute: 알림 시간 (분)
    func saveNotificationSettings(isEnabled: Bool, hour: Int, minute: Int) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("⚠️ [FirestoreNotificationRepository] No authenticated user")
            return
        }

        let notificationData: [String: Any] = [
            "isNotificationEnabled": isEnabled,
            "notificationHour": hour,
            "notificationMinute": minute,
            "notificationSettingsUpdatedAt": FieldValue.serverTimestamp()
        ]

        print("📤 [FirestoreNotificationRepository] Saving notification settings to Firestore")
        print("   UID: \(uid)")
        print("   Enabled: \(isEnabled)")
        print("   Time: \(hour):\(String(format: "%02d", minute))")

        try await db.collection("users").document(uid).setData(notificationData, merge: true)

        print("✅ [FirestoreNotificationRepository] Notification settings saved successfully")
    }
}
