//
//  PersistenceFactory.swift
//  Data
//
//  Created by 이승주 on 10/12/25.
//

import Foundation
import SwiftData
import Domain

/// Persistence 레이어 팩토리
///
/// SwiftData 구체 타입을 내부에 캡슐화하고, Domain 프로토콜만 반환합니다.
/// App 모듈은 SwiftData를 알 필요 없이 QTRepository만 받습니다.
@available(iOS 17, *)
public enum PersistenceFactory {

    /// 앱 전체에서 공유되는 ModelContainer (싱글톤)
    ///
    /// SwiftData의 ModelContainer는 앱당 하나만 존재해야 합니다.
    /// 여러 개 생성 시 iPad 멀티태스킹 환경에서 메모리 충돌 발생 가능.
    private static var _sharedContainer: ModelContainer?

    /// 앱 전체에서 공유되는 ModelContext (싱글톤)
    ///
    /// 즉시 동기화를 위해 ModelContext도 공유합니다.
    /// @MainActor로 보호되어 thread-safe합니다.
    private static var _sharedContext: ModelContext?

    /// Container/Context 생성 시 thread-safety 보장
    private static let lock = NSLock()

    /// QTRepository 구현체를 생성합니다.
    ///
    /// - Returns: QTRepository (Domain 프로토콜)
    /// - Throws: ModelContainer 생성 실패 시 에러
    public static func makeQTRepository() throws -> QTRepository {
        lock.lock()
        defer { lock.unlock() }

        // Container가 없으면 생성 (첫 호출 시 1회만)
        if _sharedContainer == nil {
            print("📦 [PersistenceFactory] Creating shared ModelContainer")
            _sharedContainer = try ModelContainer(for: QTEntryModel.self)
        }

        // Context가 없으면 생성 (첫 호출 시 1회만)
        if _sharedContext == nil {
            print("📝 [PersistenceFactory] Creating shared ModelContext")
            _sharedContext = ModelContext(_sharedContainer!)

            // ACTS → FREE 마이그레이션 실행 (첫 실행 시에만)
            performACTSMigrationIfNeeded(context: _sharedContext!)
        }

        // 싱글톤 ModelContext 사용 (즉시 동기화를 위해)
        return DefaultQTRepository(modelContext: _sharedContext!)
    }

    /// ACTS 템플릿 데이터를 FREE로 자동 마이그레이션
    ///
    /// 기존 ACTS 템플릿 기록을 찾아서 4개 필드를 하나로 병합하고 FREE로 변환합니다.
    private static func performACTSMigrationIfNeeded(context: ModelContext) {
        do {
            let descriptor = FetchDescriptor<QTEntryModel>(
                predicate: #Predicate { $0.template == "ACTS" }
            )
            let actsRecords = try context.fetch(descriptor)

            guard !actsRecords.isEmpty else {
                return
            }

            print("🔄 [Migration] Migrating \(actsRecords.count) ACTS records to FREE...")

            for record in actsRecords {
                var parts: [String] = []

                if let adoration = record.actsAdoration, !adoration.isEmpty {
                    parts.append("🙌 경배 (Adoration)\n\(adoration)")
                }
                if let confession = record.actsConfession, !confession.isEmpty {
                    parts.append("🙏 고백 (Confession)\n\(confession)")
                }
                if let thanksgiving = record.actsThanksgiving, !thanksgiving.isEmpty {
                    parts.append("✨ 감사 (Thanksgiving)\n\(thanksgiving)")
                }
                if let supplication = record.actsSupplication, !supplication.isEmpty {
                    parts.append("🙌 간구 (Supplication)\n\(supplication)")
                }

                record.template = "FREE"
                record.freeContent = parts.isEmpty ? nil : parts.joined(separator: "\n\n")
                record.actsAdoration = nil
                record.actsConfession = nil
                record.actsThanksgiving = nil
                record.actsSupplication = nil
            }

            try context.save()
            print("✅ [Migration] Successfully migrated \(actsRecords.count) ACTS records to FREE")

        } catch {
            print("❌ [Migration] Failed: \(error)")
        }
    }
}
