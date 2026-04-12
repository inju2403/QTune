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

    // ACTS 입력
    case updateAdoration(String)
    case updateConfession(String)
    case updateThanksgiving(String)
    case updateSupplication(String)

    // 자유 묵상 입력
    case updateFreeContent(String)

    // 저장
    case save

    // 기도문 관련
    case tapPrayerButton
    case dismissPrayerSheet
    case dismissPrayerError

    // 해설 관련
    case tapExplanationButton
    case dismissExplanationSheet
    case dismissExplanationError
}
