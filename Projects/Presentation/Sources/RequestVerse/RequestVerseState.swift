//
//  RequestVerseState.swift
//  QTune
//
//  Created by 이승주 on 7/26/25.
//

import Foundation
import Domain

struct RequestVerseState {
    var inputText: String = ""
    var isLoading: Bool = false
    var errorMessage: String? = nil

    // Draft
    var todayDraft: QuietTime? = nil
    var showDraftBanner: Bool = false
    var showDraftConflict: Bool = false
}
