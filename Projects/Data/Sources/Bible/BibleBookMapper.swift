//
//  BibleBookMapper.swift
//  Data
//
//  Created by 이승주 on 1/27/26.
//

import Foundation

/// 성경 책 이름을 bolls.life API 약어로 변환
public struct BibleBookMapper {
    /// 영어 책명 → 한글 책명 매핑
    private static let englishToKorean: [String: String] = [
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

    /// 영어 책명 → bolls.life 약어 매핑
    private static let bookMapping: [String: String] = [
        // 구약
        "Genesis": "GEN", "Exodus": "EXO", "Leviticus": "LEV", "Numbers": "NUM", "Deuteronomy": "DEU",
        "Joshua": "JOS", "Judges": "JDG", "Ruth": "RUT", "1 Samuel": "1SA", "2 Samuel": "2SA",
        "1 Kings": "1KI", "2 Kings": "2KI", "1 Chronicles": "1CH", "2 Chronicles": "2CH",
        "Ezra": "EZR", "Nehemiah": "NEH", "Esther": "EST", "Job": "JOB",
        "Psalms": "PSA", "Psalm": "PSA",  // Psalms 단수/복수 모두 지원
        "Proverbs": "PRO", "Ecclesiastes": "ECC", "Song of Solomon": "SNG",
        "Isaiah": "ISA", "Jeremiah": "JER", "Lamentations": "LAM", "Ezekiel": "EZK", "Daniel": "DAN",
        "Hosea": "HOS", "Joel": "JOL", "Amos": "AMO", "Obadiah": "OBA", "Jonah": "JON",
        "Micah": "MIC", "Nahum": "NAM", "Habakkuk": "HAB", "Zephaniah": "ZEP",
        "Haggai": "HAG", "Zechariah": "ZEC", "Malachi": "MAL",

        // 신약
        "Matthew": "MAT", "Mark": "MRK", "Luke": "LUK", "John": "JHN",
        "Acts": "ACT", "Romans": "ROM",
        "1 Corinthians": "1CO", "2 Corinthians": "2CO",
        "Galatians": "GAL", "Ephesians": "EPH", "Philippians": "PHP", "Colossians": "COL",
        "1 Thessalonians": "1TH", "2 Thessalonians": "2TH",
        "1 Timothy": "1TI", "2 Timothy": "2TI", "Titus": "TIT", "Philemon": "PHM",
        "Hebrews": "HEB", "James": "JAS",
        "1 Peter": "1PE", "2 Peter": "2PE",
        "1 John": "1JN", "2 John": "2JN", "3 John": "3JN",
        "Jude": "JUD", "Revelation": "REV"
    ]

    /// 영어 책명을 bolls.life 약어로 변환
    /// - Parameter bookName: "John", "Proverbs" 등의 영어 책명
    /// - Returns: "JHN", "PRO" 등의 약어, 매핑 없으면 nil
    public static func toBollsCode(_ bookName: String) -> String? {
        return bookMapping[bookName]
    }

    /// 영어 책명을 한글 책명으로 변환
    /// - Parameter bookName: "John", "Proverbs" 등의 영어 책명
    /// - Returns: "요한복음", "잠언" 등의 한글 책명, 매핑 없으면 nil
    public static func toKoreanName(_ bookName: String) -> String? {
        return englishToKorean[bookName]
    }
}
