//
//  ResultAction.swift
//  Presentation
//
//  Created by 이승주 on 11/28/25.
//

import Foundation

/// 추천 결과 화면 Action
public enum ResultAction: Equatable {
    case tapGoToQT
    case selectTemplate(TemplateKind)
    case dismissSheet
}
