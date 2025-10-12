//
//  DesignSystem.swift
//  Presentation
//
//  Created by 이승주 on 10/12/25.
//

import SwiftUI

/// QTune Design System - 은혜로운 베이지/브라운 톤
public enum DS {

    // MARK: - Color Tokens
    public enum Color {
        public static let background    = SwiftUI.Color(hex: "#F6F1EA")   // 따뜻한 아이보리
        public static let canvas        = SwiftUI.Color(hex: "#F3EDE4")   // 카드 바탕
        public static let sand          = SwiftUI.Color(hex: "#E8D8C8")
        public static let cocoa         = SwiftUI.Color(hex: "#6B4F4F")
        public static let deepCocoa     = SwiftUI.Color(hex: "#3E2C1C")
        public static let gold          = SwiftUI.Color(hex: "#D7B46A")   // 포인트
        public static let olive         = SwiftUI.Color(hex: "#71816D")   // 보조 포인트
        public static let success       = SwiftUI.Color(hex: "#2FAF66")
        public static let danger        = SwiftUI.Color(hex: "#B06B6B")
        public static let textPrimary   = SwiftUI.Color(hex: "#2B211A")
        public static let textSecondary = SwiftUI.Color.black.opacity(0.55)
        public static let divider       = SwiftUI.Color.black.opacity(0.07)
    }

    // MARK: - Border Radius
    public enum Radius {
        public static let s: CGFloat = 12
        public static let m: CGFloat = 18
        public static let l: CGFloat = 24
        public static let xl: CGFloat = 32
        public static let pill: CGFloat = 999
    }

    // MARK: - Shadow Styles
    public enum Shadow {
        public static let soft = ShadowStyle(color: .black.opacity(0.08), radius: 16, y: 8)
        public static let card = ShadowStyle(color: .black.opacity(0.10), radius: 30, y: 16)
    }

    // MARK: - Spacing
    public enum Spacing {
        public static let xs: CGFloat = 6
        public static let s: CGFloat  = 10
        public static let m: CGFloat  = 16
        public static let l: CGFloat  = 22
        public static let xl: CGFloat = 28
        public static let xxl: CGFloat = 36
    }

    // MARK: - Typography
    public enum Font {
        public static func titleXL(_ weight: SwiftUI.Font.Weight = .semibold) -> SwiftUI.Font {
            .system(size: 34, weight: weight, design: .rounded)
        }

        public static func titleL(_ weight: SwiftUI.Font.Weight = .semibold) -> SwiftUI.Font {
            .system(size: 28, weight: weight, design: .rounded)
        }

        public static func titleM(_ weight: SwiftUI.Font.Weight = .semibold) -> SwiftUI.Font {
            .system(size: 22, weight: weight, design: .rounded)
        }

        public static func bodyL(_ weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: 17, weight: weight, design: .rounded)
        }

        public static func bodyM(_ weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: 15, weight: weight, design: .rounded)
        }

        public static func caption(_ weight: SwiftUI.Font.Weight = .medium) -> SwiftUI.Font {
            .system(size: 13, weight: weight, design: .rounded)
        }
    }
}

// MARK: - HEX Color Extension
extension SwiftUI.Color {
    init(hex: String) {
        var hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Shadow Style
public struct ShadowStyle {
    let color: SwiftUI.Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    public init(color: SwiftUI.Color, radius: CGFloat, x: CGFloat = 0, y: CGFloat) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
}

// MARK: - Shadow View Extension
extension View {
    public func dsShadow(_ style: ShadowStyle) -> some View {
        shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}
