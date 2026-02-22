//
//  FetchVerseDirectUseCase.swift
//  Domain
//
//  Created by 이승주 on 2/18/26.
//

import Foundation

/// 구절 직접 조회 UseCase
/// GPT 없이 Bible API에서 구절 본문만 가져옴
public protocol FetchVerseDirectUseCase: Sendable {
    func execute(verseRef: String, translation: String) async throws -> Verse
}
