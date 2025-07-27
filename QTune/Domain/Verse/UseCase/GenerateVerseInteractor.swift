//
//  GenerateVerseInteractor.swift
//  QTune
//
//  Created by 이승주 on 7/26/25.
//

import Foundation

final class GenerateVerseInteractor: GenerateVerseUseCase {
    private let repository: VerseRepository

    init(repository: VerseRepository) {
        self.repository = repository
    }

    func execute(prompt: String) async throws -> GeneratedVerse {
        return try await repository.generate(prompt: prompt)
    }
}
