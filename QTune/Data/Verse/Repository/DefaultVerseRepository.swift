//
//  DefaultVerseRepository.swift
//  QTune
//
//  Created by 이승주 on 7/26/25.
//

import Foundation

final class DefaultVerseRepository: VerseRepository {
    func generate(prompt: String) async throws -> GeneratedVerse {
        let verse = Verse(
            book: "이사야",
            chapter: 41,
            verse: 10,
            text: "두려워하지 말라 내가 너와 함께 함이라",
            translation: "개역개정"
        )

        return GeneratedVerse(
            verse: verse,
            reason: "\"\(prompt)\"이라는 상황 속에서 하나님이 너를 버리지 않으신다는 위로의 말씀입니다."
        )
    }
}
