//
//  FirestoreUpdateNotificationSettingsUseCase.swift
//  App
//
//  Created by 이승주 on 2/14/26.
//

import Foundation
import Domain

/// Domain의 UpdateNotificationSettingsUseCase를 래핑하여 Firestore 저장 로직을 추가하는 UseCase
///
/// Clean Architecture 원칙:
/// - Domain 레이어는 Firebase를 알 수 없음
/// - App 레이어에서 Domain UseCase + Firestore 저장을 조합
///
/// 실행 순서:
/// 1. UserDefaults에 저장 (Domain UseCase)
/// 2. Firestore에 저장 (App 레이어 Repository)
final class FirestoreUpdateNotificationSettingsUseCase: UpdateNotificationSettingsUseCase {

    private let domainUseCase: UpdateNotificationSettingsUseCase
    private let firestoreRepository: FirestoreNotificationRepository

    init(
        domainUseCase: UpdateNotificationSettingsUseCase,
        firestoreRepository: FirestoreNotificationRepository
    ) {
        self.domainUseCase = domainUseCase
        self.firestoreRepository = firestoreRepository
    }

    func execute(isEnabled: Bool, hour: Int, minute: Int) async throws {
        print("🔔 [FirestoreUpdateNotificationSettingsUseCase] Executing...")
        print("   Enabled: \(isEnabled)")
        print("   Time: \(hour):\(String(format: "%02d", minute))")

        // 1. UserDefaults에 저장 (Domain UseCase)
        print("📝 [FirestoreUpdateNotificationSettingsUseCase] Step 1: Saving to UserDefaults...")
        try await domainUseCase.execute(isEnabled: isEnabled, hour: hour, minute: minute)
        print("✅ [FirestoreUpdateNotificationSettingsUseCase] Step 1 complete")

        // 2. Firestore에 저장 (App 레이어)
        print("📝 [FirestoreUpdateNotificationSettingsUseCase] Step 2: Saving to Firestore...")
        try await firestoreRepository.saveNotificationSettings(
            isEnabled: isEnabled,
            hour: hour,
            minute: minute
        )
        print("✅ [FirestoreUpdateNotificationSettingsUseCase] Step 2 complete")

        print("✅ [FirestoreUpdateNotificationSettingsUseCase] All steps completed successfully!")
    }
}
