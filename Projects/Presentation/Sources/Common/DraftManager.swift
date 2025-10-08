//
//  DraftManager.swift
//  Presentation
//
//  Created by 이승주 on 10/4/25.
//

import Foundation
import Domain

public actor DraftManager {
    public static let shared = DraftManager()
    private var cache: [String: QuietTime] = [:] // key = yyyy-MM-dd

    public func loadTodayDraft(userId: String, now: Date = .now, tz: TimeZone = .current) async -> QuietTime? {
        let key = Self.key(for: now, tz: tz)
        return cache[key]
    }

    public func saveDraft(_ qt: QuietTime, userId: String, now: Date = .now, tz: TimeZone = .current) async {
        let key = Self.key(for: now, tz: tz)
        var t = qt
        t.updatedAt = now
        cache[key] = t
    }

    public func clearTodayDraft(userId: String, now: Date = .now, tz: TimeZone = .current) async {
        let key = Self.key(for: now, tz: tz)
        cache.removeValue(forKey: key)
    }

    private static func key(for date: Date, tz: TimeZone) -> String {
        var cal = Calendar.current
        cal.timeZone = tz
        let d = cal.dateComponents([.year,.month,.day], from: date)
        return String(format: "%04d-%02d-%02d", d.year!, d.month!, d.day!)
    }
}
