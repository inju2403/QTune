//
//  Colors.swift
//  Presentation
//
//  Created by 이승주 on 10/13/25.
//

import SwiftUI

public enum DSColor {
    // Light sunset background (더 밝게 - 가독성 개선)
    public static let bgTop      = Color(hex: "#FAF6F1")   // 밝은 오트밀 베이지
    public static let bgMid      = Color(hex: "#F5EEE6")   // 연한 샌드
    public static let bgBot      = Color(hex: "#EFE5D8")   // 연한 베이지

    // Point colors (탭 색상 포함)
    public static let cocoa      = Color(hex: "#6A4A3C")   // Text/icons
    public static let cocoaDeep  = Color(hex: "#3E2C1C")   // Deep brown
    public static let gold       = Color(hex: "#D8B46A")   // Gold accent
    public static let accent     = Color(hex: "#2E8B6C")   // CTA green
    public static let accent2    = Color(hex: "#1F6D56")   // CTA green dark
    public static let mocha      = Color(hex: "#8B6F47")   // 탭 선택 색상
    public static let lightBrown = Color(hex: "#B8A598")   // 탭 비선택 색상

    // Card/stroke/text
    public static let card       = Color.white.opacity(0.98)  // 더 밝게
    public static let stroke     = Color.black.opacity(0.06)  // 더 연하게
    public static let textPri    = Color(hex: "#1A1412")      // 더 짙게 (대비 개선)
    public static let textSec    = Color.black.opacity(0.50)
    public static let placeholder = Color.black.opacity(0.25) // placeholder 전용

    // Legacy support
    public static let success    = Color(hex: "#2FAF66")
    public static let olive      = Color(hex: "#9DC183")
    public static let divider    = Color.black.opacity(0.06)
}

