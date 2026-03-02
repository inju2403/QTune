//
//  QTTemplateType.swift
//  Presentation
//
//  Created by 이승주 on 10/12/25.
//

import Foundation

/// QT 템플릿 타입
public enum QTTemplateType: String, CaseIterable {
    case soap = "SOAP"
    case free = "FREE"

    var displayName: String {
        switch self {
        case .soap: return "S.O.A.P"
        case .free: return "자유 묵상"
        }
    }
}

/// S.O.A.P 템플릿 상태
public struct SOAPTemplate: Equatable {
    public var observation: String = ""      // O: 관찰
    public var application: String = ""      // A: 적용
    public var prayer: String = ""           // P: 기도

    public init() {}

    var observationPlaceholder: String {
        "반복되는 단어/대조/약속은 무엇인가요?"
    }

    var applicationPlaceholder: String {
        "오늘 구체적으로 무엇을 하겠나요?"
    }

    var prayerPlaceholder: String {
        "주님, 오늘 말씀대로 … 하게 해주세요."
    }
}

/// 자유 묵상 템플릿 상태
public struct FreeTemplate: Equatable {
    public var content: String = ""          // 자유 묵상 내용

    public init() {}

    var contentPlaceholder: String {
        "오늘 말씀을 통해 받은 은혜와 깨달음을 자유롭게 기록해보세요."
    }
}
