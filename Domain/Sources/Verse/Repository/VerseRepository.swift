//
//  VerseRepository.swift
//  QTune
//
//  Created by 이승주 on 7/26/25.
//

import Foundation

public protocol VerseRepository {
    func generate(prompt: String) async throws -> GeneratedVerse
}
