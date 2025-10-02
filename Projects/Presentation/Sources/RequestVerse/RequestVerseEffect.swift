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
    case navigateToResult(GeneratedVerse)
}
