//
//  GeneratedVerse.swift
//  QTune
//
//  Created by 이승주 on 7/26/25.
//

import Foundation

public struct GeneratedVerse: Equatable {
    let verse: Verse
    let reason: String

    public init(verse: Verse, reason: String) {
        self.verse = verse
        self.reason = reason
    }
}
