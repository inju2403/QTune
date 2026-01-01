//
//  RequestVerseEffect.swift
//  QTune
//
//  Created by 이승주 on 7/26/25.
//

import Foundation
import Domain

enum RequestVerseEffect {
    case showError(String)
    case showToast(String)
    case presentDraftConflict
    case navigateToEditor(QuietTime)           // 드래프트 이어서 작성
    case navigateToQTEditor(verse: Verse, korean: String, rationale: String)  // 결과로 QT 작성하러 가기
}
