//
//  BibleBookMapper.swift
//  Data
//
//  Created by 이승주 on 1/27/26.
//

import Foundation

/// 성경 책 이름을 bolls.life API 약어로 변환
public struct BibleBookMapper {
    /// 한글 책명/약어 → 영어 책명 매핑
    private static let koreanToEnglish: [String: String] = [
        // 구약
        "창세기": "Genesis", "창": "Genesis",
        "출애굽기": "Exodus", "출": "Exodus",
        "레위기": "Leviticus", "레": "Leviticus",
        "민수기": "Numbers", "민": "Numbers",
        "신명기": "Deuteronomy", "신": "Deuteronomy",
        "여호수아": "Joshua", "수": "Joshua",
        "사사기": "Judges", "삿": "Judges",
        "룻기": "Ruth", "룻": "Ruth",
        "사무엘상": "1 Samuel", "삼상": "1 Samuel",
        "사무엘하": "2 Samuel", "삼하": "2 Samuel",
        "열왕기상": "1 Kings", "왕상": "1 Kings",
        "열왕기하": "2 Kings", "왕하": "2 Kings",
        "역대상": "1 Chronicles", "대상": "1 Chronicles",
        "역대하": "2 Chronicles", "대하": "2 Chronicles",
        "에스라": "Ezra", "스": "Ezra",
        "느헤미야": "Nehemiah", "느": "Nehemiah",
        "에스더": "Esther", "에": "Esther",
        "욥기": "Job", "욥": "Job",
        "시편": "Psalms", "시": "Psalms",
        "잠언": "Proverbs", "잠": "Proverbs",
        "전도서": "Ecclesiastes", "전": "Ecclesiastes",
        "아가": "Song of Solomon",
        "이사야": "Isaiah", "사": "Isaiah",
        "예레미야": "Jeremiah", "렘": "Jeremiah",
        "예레미야애가": "Lamentations", "애": "Lamentations",
        "에스겔": "Ezekiel", "겔": "Ezekiel",
        "다니엘": "Daniel", "단": "Daniel",
        "호세아": "Hosea", "호": "Hosea",
        "요엘": "Joel", "욜": "Joel",
        "아모스": "Amos", "암": "Amos",
        "오바댜": "Obadiah", "옵": "Obadiah",
        "요나": "Jonah", "욘": "Jonah",
        "미가": "Micah", "미": "Micah",
        "나훔": "Nahum", "나": "Nahum",
        "하박국": "Habakkuk", "합": "Habakkuk",
        "스바냐": "Zephaniah", "습": "Zephaniah",
        "학개": "Haggai", "학": "Haggai",
        "스가랴": "Zechariah", "슥": "Zechariah",
        "말라기": "Malachi", "말": "Malachi",
        // 신약
        "마태복음": "Matthew", "마": "Matthew",
        "마가복음": "Mark", "막": "Mark",
        "누가복음": "Luke", "눅": "Luke",
        "요한복음": "John", "요": "John",
        "사도행전": "Acts", "행": "Acts",
        "로마서": "Romans", "롬": "Romans",
        "고린도전서": "1 Corinthians", "고전": "1 Corinthians",
        "고린도후서": "2 Corinthians", "고후": "2 Corinthians",
        "갈라디아서": "Galatians", "갈": "Galatians",
        "에베소서": "Ephesians", "엡": "Ephesians",
        "빌립보서": "Philippians", "빌": "Philippians",
        "골로새서": "Colossians", "골": "Colossians",
        "데살로니가전서": "1 Thessalonians", "살전": "1 Thessalonians",
        "데살로니가후서": "2 Thessalonians", "살후": "2 Thessalonians",
        "디모데전서": "1 Timothy", "딤전": "1 Timothy",
        "디모데후서": "2 Timothy", "딤후": "2 Timothy",
        "디도서": "Titus", "딛": "Titus",
        "빌레몬서": "Philemon", "몬": "Philemon",
        "히브리서": "Hebrews", "히": "Hebrews",
        "야고보서": "James", "약": "James",
        "베드로전서": "1 Peter", "벧전": "1 Peter",
        "베드로후서": "2 Peter", "벧후": "2 Peter",
        "요한일서": "1 John", "요일": "1 John",
        "요한이서": "2 John", "요이": "2 John",
        "요한삼서": "3 John", "요삼": "3 John",
        "유다서": "Jude", "유": "Jude",
        "요한계시록": "Revelation", "계": "Revelation"
    ]

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

    /// 영어 책명을 전통적 book_id (1=창세기 ... 66=요한계시록) 로 변환
    /// 로컬 sqlite DB 의 book_id 와 1:1 매칭된다.
    public static func toBookId(_ bookName: String) -> Int? {
        return bookIdMapping[bookName]
    }

    /// 영어 책명 → book_id (1~66) 매핑
    private static let bookIdMapping: [String: Int] = [
        "Genesis": 1, "Exodus": 2, "Leviticus": 3, "Numbers": 4, "Deuteronomy": 5,
        "Joshua": 6, "Judges": 7, "Ruth": 8, "1 Samuel": 9, "2 Samuel": 10,
        "1 Kings": 11, "2 Kings": 12, "1 Chronicles": 13, "2 Chronicles": 14,
        "Ezra": 15, "Nehemiah": 16, "Esther": 17, "Job": 18,
        "Psalms": 19, "Psalm": 19,
        "Proverbs": 20, "Ecclesiastes": 21, "Song of Solomon": 22,
        "Isaiah": 23, "Jeremiah": 24, "Lamentations": 25, "Ezekiel": 26, "Daniel": 27,
        "Hosea": 28, "Joel": 29, "Amos": 30, "Obadiah": 31, "Jonah": 32,
        "Micah": 33, "Nahum": 34, "Habakkuk": 35, "Zephaniah": 36,
        "Haggai": 37, "Zechariah": 38, "Malachi": 39,
        "Matthew": 40, "Mark": 41, "Luke": 42, "John": 43,
        "Acts": 44, "Romans": 45,
        "1 Corinthians": 46, "2 Corinthians": 47,
        "Galatians": 48, "Ephesians": 49, "Philippians": 50, "Colossians": 51,
        "1 Thessalonians": 52, "2 Thessalonians": 53,
        "1 Timothy": 54, "2 Timothy": 55, "Titus": 56, "Philemon": 57,
        "Hebrews": 58, "James": 59,
        "1 Peter": 60, "2 Peter": 61,
        "1 John": 62, "2 John": 63, "3 John": 64,
        "Jude": 65, "Revelation": 66
    ]

    /// 영어 책명을 한글 책명으로 변환
    /// - Parameter bookName: "John", "Proverbs" 등의 영어 책명
    /// - Returns: "요한복음", "잠언" 등의 한글 책명, 매핑 없으면 nil
    public static func toKoreanName(_ bookName: String) -> String? {
        return englishToKorean[bookName]
    }

    /// 한글 책명/약어를 영어 책명으로 변환
    /// - Parameter koreanName: "시편", "시", "요한복음", "요" 등의 한글 책명 또는 약어
    /// - Returns: "Psalms", "John" 등의 영어 책명, 매핑 없으면 nil
    public static func toEnglishName(_ koreanName: String) -> String? {
        return koreanToEnglish[koreanName]
    }
}
