//
//  VerseSearchAction.swift
//  Presentation
//
//  Created by 이승주 on 2/18/26.
//

import Foundation
import Domain

/// 구절 직접 찾기 화면의 사용자 액션
public enum VerseSearchAction: Equatable {
    case updateSearch(String)
    case selectTranslation(Translation)
    case tapSearch
    case tapGoToQT
    case dismissError
    case onAppear
    // 해설 관련
    case tapFetchExplanation
    case dismissExplanationError
}

/// 구절 직접 찾기 화면의 사이드 이펙트
public enum VerseSearchEffect {
    case navigateToQTEditor(verse: Verse, explanation: String?)
}
