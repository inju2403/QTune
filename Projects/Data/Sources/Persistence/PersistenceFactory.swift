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
        }

        // 싱글톤 ModelContext 사용 (즉시 동기화를 위해)
        return DefaultQTRepository(modelContext: _sharedContext!)
    }
}
