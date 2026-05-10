//
//  BibleLocalDB.swift
//  Data
//
//  Created by 이승주 on 4/21/26.
//

import Foundation
import SQLite3

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

/// 번들된 bible.sqlite 를 읽기 전용으로 여는 래퍼.
/// 앱에 박혀있는 성경 DB 를 로컬에서 질의해 네트워크 호출을 피한다.
public final class BibleLocalDB {
    public static let shared = BibleLocalDB()

    private var db: OpaquePointer?
    private let queue = DispatchQueue(label: "com.qtune.data.bible-local-db")
    private let isOpen: Bool

    private init() {
        let bundle = Bundle(for: BibleLocalDB.self)
        guard let url = bundle.url(forResource: "bible", withExtension: "sqlite") else {
            self.isOpen = false
            return
        }
        var handle: OpaquePointer?
        // 번들 리소스는 읽기 전용 / 변하지 않음을 명시 → WAL 사이드카 시도/락킹 모두 스킵.
        let uri = "file:\(url.path)?immutable=1"
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX | SQLITE_OPEN_URI
        let rc = sqlite3_open_v2(uri, &handle, flags, nil)
        if rc == SQLITE_OK {
            self.db = handle
            self.isOpen = true
        } else {
            if let handle {
                sqlite3_close(handle)
            }
            self.isOpen = false
        }
    }

    deinit {
        if let db {
            sqlite3_close(db)
        }
    }

    /// 주어진 범위의 절을 합친 본문을 반환한다. 매칭되는 행이 없으면 nil.
    /// - Parameters:
    ///   - bookId: 1(창세기) ~ 66(요한계시록)
    ///   - chapter: 장 번호
    ///   - startVerse: 시작 절
    ///   - endVerse: 끝 절 (단일이면 start 와 동일)
    ///   - translation: "WEB", "KJV", "KRV"
    public func getVerseText(
        bookId: Int,
        chapter: Int,
        startVerse: Int,
        endVerse: Int,
        translation: String
    ) -> String? {
        guard isOpen, let db else { return nil }

        return queue.sync {
            let sql = """
                SELECT verse, text
                FROM verses
                WHERE book_id = ? AND chapter = ?
                  AND verse BETWEEN ? AND ?
                  AND translation = ?
                ORDER BY verse ASC
            """
            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
                return nil
            }
            defer { sqlite3_finalize(stmt) }

            sqlite3_bind_int(stmt, 1, Int32(bookId))
            sqlite3_bind_int(stmt, 2, Int32(chapter))
            sqlite3_bind_int(stmt, 3, Int32(startVerse))
            sqlite3_bind_int(stmt, 4, Int32(endVerse))
            let tr = translation.uppercased()
            sqlite3_bind_text(stmt, 5, tr, -1, SQLITE_TRANSIENT)

            var pieces: [String] = []
            while sqlite3_step(stmt) == SQLITE_ROW {
                if let cStr = sqlite3_column_text(stmt, 1) {
                    let s = String(cString: cStr).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !s.isEmpty { pieces.append(s) }
                }
            }
            return pieces.isEmpty ? nil : pieces.joined(separator: " ")
        }
    }
}
