//
//  Colors.swift
//  Presentation
//
//  Created by 이승주 on 10/13/25.
//

import SwiftUI

public enum DSColor {
    // Sunset gradient layers
    public static let bgTop      = Color(hex: "#1E0F0A")   // Very deep cocoa
    public static let bgMid      = Color(hex: "#3B2416")   // Brown-burgundy
    public static let bgBottom   = Color(hex: "#5B3A1E")   // Sunset brown

    // Sun/glow colors
    public static let sunCore    = Color(hex: "#D5A96E")   // Amber-gold
    public static let sunEdge    = Color(hex: "#B7813F")   // Warm edge

    // UI colors
    public static let card       = Color(hex: "#F3E9DE")
    public static let textPri    = Color(hex: "#2B211A")
    public static let textSec    = Color.white.opacity(0.75)
    public static let gold       = Color(hex: "#E7C67C")
    public static let olive      = Color(hex: "#7C8B6D")

    // CTA colors
    public static let accent     = Color(hex: "#3D8F6C")   // CTA green
    public static let accent2    = Color(hex: "#276953")

    // Legacy support (keeping for backward compatibility)
    public static let success    = Color(hex: "#2FAF66")
    public static let divider    = Color.white.opacity(0.15)
}

// HEX color extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
