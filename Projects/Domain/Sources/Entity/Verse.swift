//
//  Verse.swift
//  QTune
//
//  Created by 이승주 on 7/26/25.
//

import Foundation

public struct Verse: Equatable, Hashable {
    public var id: String { "\(book) \(chapter):\(verse)" }
    public var localizedId: String { "\(localizedBookName) \(chapter):\(verse)" }
    public let book: String            // 성경 책 이름, 예: "John"
    public let chapter: Int            // 장 번호, 예: 3
    public let verse: Int              // 절 번호, 예: 16
    public let text: String            // 말씀 본문, 예: "For God so loved the world..."
    public let translation: String      // 번역본, 예: "KJV", "NIV", "개역개정"

    public init(
        book: String,
        chapter: Int,
        verse: Int,
        text: String,
        translation: String
    ) {
        self.book = book
        self.chapter = chapter
        self.verse = verse
        self.text = text
        self.translation = translation
    }

    /// 한글 책명 반환 (한글 역본일 때 사용)
    public var koreanBookName: String {
        let mapping: [String: String] = [
            // 구약
            "Genesis": "창세기", "Exodus": "출애굽기", "Leviticus": "레위기", "Numbers": "민수기", "Deuteronomy": "신명기",
            "Joshua": "여호수아", "Judges": "사사기", "Ruth": "룻기", "1 Samuel": "사무엘상", "2 Samuel": "사무엘하",
            "1 Kings": "열왕기상", "2 Kings": "열왕기하", "1 Chronicles": "역대상", "2 Chronicles": "역대하",
            "Ezra": "에스라", "Nehemiah": "느헤미야", "Esther": "에스더", "Job": "욥기",
            "Psalms": "시편", "Psalm": "시편",
            "Proverbs": "잠언", "Ecclesiastes": "전도서", "Song of Solomon": "아가",
            "Isaiah": "이사야", "Jeremiah": "예레미야", "Lamentations": "예레미야애가", "Ezekiel": "에스겔", "Daniel": "다니엘",
            "Hosea": "호세아", "Joel": "요엘", "Amos": "아모스", "Obadiah": "오바댜", "Jonah": "요나",
            "Micah": "미가", "Nahum": "나훔", "Habakkuk": "하박국", "Zephaniah": "스바냐",
            "Haggai": "학개", "Zechariah": "스가랴", "Malachi": "말라기",
            // 신약
            "Matthew": "마태복음", "Mark": "마가복음", "Luke": "누가복음", "John": "요한복음",
            "Acts": "사도행전", "Romans": "로마서",
            "1 Corinthians": "고린도전서", "2 Corinthians": "고린도후서",
            "Galatians": "갈라디아서", "Ephesians": "에베소서", "Philippians": "빌립보서", "Colossians": "골로새서",
            "1 Thessalonians": "데살로니가전서", "2 Thessalonians": "데살로니가후서",
            "1 Timothy": "디모데전서", "2 Timothy": "디모데후서", "Titus": "디도서", "Philemon": "빌레몬서",
            "Hebrews": "히브리서", "James": "야고보서",
            "1 Peter": "베드로전서", "2 Peter": "베드로후서",
            "1 John": "요한일서", "2 John": "요한이서", "3 John": "요한삼서",
            "Jude": "유다서", "Revelation": "요한계시록"
        ]
        return mapping[book] ?? book
    }

    /// 역본에 맞는 책명 반환 (KRV이면 한글, 아니면 영어)
    public var localizedBookName: String {
        if translation.uppercased() == "KRV" {
            return koreanBookName
        }
        return book
    }
}
