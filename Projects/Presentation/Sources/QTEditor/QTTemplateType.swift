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
    case acts = "ACTS"

    var displayName: String {
        switch self {
        case .soap: return "S.O.A.P"
        case .acts: return "A.C.T.S"
        }
    }
}

/// S.O.A.P 템플릿 상태
public struct SOAPTemplate {
    var observation: String = ""      // O: 관찰
    var application: String = ""      // A: 적용
    var prayer: String = ""           // P: 기도

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

/// A.C.T.S 템플릿 상태
public struct ACTSTemplate {
    var adoration: String = ""        // A: 찬양
    var confession: String = ""       // C: 회개
    var thanksgiving: String = ""     // T: 감사
    var supplication: String = ""     // S: 간구

    var adorationPlaceholder: String {
        "하나님의 어떤 성품이 드러났나요?"
    }

    var confessionPlaceholder: String {
        "말씀에 비춰 돌아볼 부분은?"
    }

    var thanksgivingPlaceholder: String {
        "감사해야 할 일 3가지는?"
    }

    var supplicationPlaceholder: String {
        "오늘 드릴 간구는?"
    }
}
