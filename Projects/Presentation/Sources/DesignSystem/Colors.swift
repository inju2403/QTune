//
//  Colors.swift
//  Presentation
//
//  Created by 이승주 on 10/13/25.
//

import SwiftUI

public enum DSColor {
    // Light sunset background
    public static let bgTop      = Color(hex: "#F8F1E8")   // Bright ivory
    public static let bgMid      = Color(hex: "#F1E6D7")   // Warm sand
    public static let bgBot      = Color(hex: "#E9D7C4")   // Soft beige

    // Point colors
    public static let cocoa      = Color(hex: "#6A4A3C")   // Text/icons
    public static let cocoaDeep  = Color(hex: "#3E2C1C")   // Deep brown
    public static let gold       = Color(hex: "#D8B46A")   // Gold accent
    public static let accent     = Color(hex: "#2E8B6C")   // CTA green
    public static let accent2    = Color(hex: "#1F6D56")   // CTA green dark

    // Card/stroke/text
    public static let card       = Color.white.opacity(0.96)
    public static let stroke     = Color.black.opacity(0.08)
    public static let textPri    = Color(hex: "#2B211A")
    public static let textSec    = Color.black.opacity(0.55)

    // Legacy support
    public static let success    = Color(hex: "#2FAF66")
    public static let olive      = Color(hex: "#7C8B6D")
    public static let divider    = Color.black.opacity(0.08)
}

