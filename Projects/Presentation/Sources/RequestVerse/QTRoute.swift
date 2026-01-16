//
//  QTRoute.swift
//  Presentation
//
//  Created by 이승주 on 10/19/25.
//

import Foundation
import Domain

/// QT 작성 플로우 네비게이션 라우트
public enum QTRoute: Hashable {
    case result(GeneratedVerseResult)
    case editor(template: TemplateKind, verseEN: String, verseRef: String, explKR: String, rationale: String, verse: Verse)
}

/// 템플릿 종류
public enum TemplateKind: String, Hashable {
    case soap
    case acts
}
