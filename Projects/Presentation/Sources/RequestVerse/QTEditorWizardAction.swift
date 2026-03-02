//
//  QTEditorWizardAction.swift
//  Presentation
//
//  Created by 이승주 on 11/28/25.
//

import Foundation

/// QT 작성 마법사 화면 Action
public enum QTEditorWizardAction: Equatable {
    // 단계 이동
    case stepNext
    case stepPrevious

    // SOAP 입력
    case updateObservation(String)
    case updateApplication(String)
    case updatePrayer(String)

    // 자유 묵상 입력
    case updateFreeContent(String)

    // 저장
    case save
}
