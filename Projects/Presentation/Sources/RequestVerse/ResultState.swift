//
//  ResultState.swift
//  Presentation
//
//  Created by 이승주 on 11/28/25.
//

import Foundation
import Domain

/// 추천 결과 화면 State
public struct ResultState: Equatable {
    public var result: GeneratedVerseResult
    public var showTemplateSheet: Bool

    public init(
        result: GeneratedVerseResult,
        showTemplateSheet: Bool = false
    ) {
        self.result = result
        self.showTemplateSheet = showTemplateSheet
    }
}
