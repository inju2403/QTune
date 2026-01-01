//
//  QTEditorAction.swift
//  Presentation
//
//  Created by 이승주 on 10/12/25.
//

import Foundation
import Domain

/// QT 작성 화면 Action
public enum QTEditorAction: Equatable {
    case loadQT(QuietTime)
    case switchTemplate(QTTemplateType)
    case updateSOAPObservation(String)
    case updateSOAPApplication(String)
    case updateSOAPPrayer(String)
    case updateACTSAdoration(String)
    case updateACTSConfession(String)
    case updateACTSThanksgiving(String)
    case updateACTSSupplication(String)
    case saveQT(QuietTime)
}
