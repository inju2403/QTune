//
//  QT.swift
//  QTune
//
//  Created by 이승주 on 7/26/25.
//

import Foundation

struct QuietTime: Identifiable, Equatable {
    let id: UUID
    let verse: Verse       // 추천된 말씀
    let memo: String       // 사용자의 묵상 내용
    let date: Date         // 기록된 날짜
}

