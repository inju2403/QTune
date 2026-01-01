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

    /// QTRepository 구현체를 생성합니다.
    ///
    /// - Returns: QTRepository (Domain 프로토콜)
    /// - Throws: ModelContainer 생성 실패 시 에러
    public static func makeQTRepository() throws -> QTRepository {
        let container = try ModelContainer(for: QTEntryModel.self)
        let context = ModelContext(container)
        return DefaultQTRepository(modelContext: context)
    }
}
