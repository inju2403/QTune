//
//  RequestVerseAction.swift
//  QTune
//
//  Created by 이승주 on 7/26/25.
//

import Foundation
import Domain

enum RequestVerseAction {
    case onAppear(userId: String)
    case updateInput(String)
    case tapRequest
    case tapResumeDraft
    case tapDiscardDraft
}
