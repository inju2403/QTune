//
//  GenerateVerseInteractor.swift
//  QTune
//
//  Created by 이승주 on 7/26/25.
//

import Foundation

public final class GenerateVerseInteractor: GenerateVerseUseCase {
    private let repository: VerseRepository

    public init(repository: VerseRepository) {
        self.repository = repository
    }

    public func execute(prompt: String) async throws -> GeneratedVerse {
        return try await repository.generate(prompt: prompt)
    }
}
