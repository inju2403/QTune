//
//  GenerateVerseUseCase.swift
//  QTune
//
//  Created by 이승주 on 7/26/25.
//

import Foundation

protocol GenerateVerseUseCase {
    func execute(prompt: String) async throws -> GeneratedVerse
}
