//
//  DesignSystem.swift
//  Presentation
//
//  Created by 이승주 on 10/12/25.
//

import SwiftUI
import Domain

/// QTune Design System - 은혜로운 베이지/브라운 톤
public enum DS {

    // MARK: - Color Tokens
    public enum Color {
        // Background
        public static let background    = SwiftUI.Color(hex: "#FAF6F1")   // 밝은 오트밀 베이지 (개선)
        public static let bgTop         = SwiftUI.Color(hex: "#FAF6F1")   // 밝은 오트밀 베이지
        public static let bgMid         = SwiftUI.Color(hex: "#F5EEE6")   // 연한 샌드
        public static let bgBot         = SwiftUI.Color(hex: "#EFE5D8")   // 연한 베이지

        // Card & Canvas
        public static let canvas        = SwiftUI.Color(hex: "#FFFFFF")   // 순백 카드 (개선)
        public static let card          = SwiftUI.Color.white.opacity(0.98)  // 더 밝게

        // Basic Colors
        public static let sand          = SwiftUI.Color(hex: "#E8D8C8")
        public static let cocoa         = SwiftUI.Color(hex: "#6A4A3C")   // Text/icons
        public static let deepCocoa     = SwiftUI.Color(hex: "#3E2C1C")   // Deep brown
        public static let cocoaDeep     = SwiftUI.Color(hex: "#3E2C1C")   // Deep brown (alias)

        // Accents
        public static let gold          = SwiftUI.Color(hex: "#D8B46A")   // Gold accent
        public static let accent        = SwiftUI.Color(hex: "#2E8B6C")   // CTA green
        public static let accent2       = SwiftUI.Color(hex: "#1F6D56")   // CTA green dark
        public static let olive         = SwiftUI.Color(hex: "#9DC183")   // 보조 포인트 (SOAP)

        // Tab Colors
        public static let mocha         = SwiftUI.Color(hex: "#8B6F47")   // 탭 선택
        public static let lightBrown    = SwiftUI.Color(hex: "#B8A598")   // 탭 비선택

        // Status
        public static let success       = SwiftUI.Color(hex: "#2FAF66")
        public static let danger        = SwiftUI.Color(hex: "#B06B6B")

        // Text
        public static let textPrimary   = SwiftUI.Color(hex: "#1A1412")   // 더 짙게 (대비 개선)
        public static let textPri       = SwiftUI.Color(hex: "#1A1412")   // alias
        public static let textSecondary = SwiftUI.Color.black.opacity(0.50)
        public static let textSec       = SwiftUI.Color.black.opacity(0.50)  // alias
        public static let placeholder   = SwiftUI.Color.black.opacity(0.25)  // placeholder 전용

        // Borders
        public static let stroke        = SwiftUI.Color.black.opacity(0.06)  // 더 연하게
        public static let divider       = SwiftUI.Color.black.opacity(0.06)
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
        public static func titleXL(_ weight: SwiftUI.Font.Weight = .semibold, scale: FontScale = .medium) -> SwiftUI.Font {
            .system(size: 34 * scale.multiplier, weight: weight, design: .serif)
        }

        public static func titleL(_ weight: SwiftUI.Font.Weight = .semibold, scale: FontScale = .medium) -> SwiftUI.Font {
            .system(size: 28 * scale.multiplier, weight: weight, design: .serif)
        }

        public static func titleM(_ weight: SwiftUI.Font.Weight = .semibold, scale: FontScale = .medium) -> SwiftUI.Font {
            .system(size: 22 * scale.multiplier, weight: weight, design: .serif)
        }

        public static func titleS(_ weight: SwiftUI.Font.Weight = .semibold, scale: FontScale = .medium) -> SwiftUI.Font {
            .system(size: 19 * scale.multiplier, weight: weight, design: .serif)
        }

        public static func bodyL(_ weight: SwiftUI.Font.Weight = .regular, scale: FontScale = .medium) -> SwiftUI.Font {
            .system(size: 17 * scale.multiplier, weight: weight, design: .default)
        }

        public static func bodyM(_ weight: SwiftUI.Font.Weight = .regular, scale: FontScale = .medium) -> SwiftUI.Font {
            .system(size: 15 * scale.multiplier, weight: weight, design: .default)
        }

        public static func caption(_ weight: SwiftUI.Font.Weight = .medium, scale: FontScale = .medium) -> SwiftUI.Font {
            .system(size: 13 * scale.multiplier, weight: weight, design: .default)
        }

        // 영문 구절용 세리프 폰트
        public static func verse(_ size: CGFloat = 17, _ weight: SwiftUI.Font.Weight = .regular, scale: FontScale = .medium) -> SwiftUI.Font {
            .system(size: size * scale.multiplier, weight: weight, design: .serif)
        }
    }
}

// MARK: - HEX Color Extension
extension SwiftUI.Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
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

// MARK: - Font Scale Environment
private struct FontScaleKey: EnvironmentKey {
    static let defaultValue: FontScale = .medium
}

private struct LineSpacingKey: EnvironmentKey {
    static let defaultValue: LineSpacing = .normal
}

extension EnvironmentValues {
    public var fontScale: FontScale {
        get { self[FontScaleKey.self] }
        set { self[FontScaleKey.self] = newValue }
    }

    public var lineSpacing: LineSpacing {
        get { self[LineSpacingKey.self] }
        set { self[LineSpacingKey.self] = newValue }
    }
}

// MARK: - Dynamic Line Spacing View Extension
extension View {
    /// 동적 행간을 적용합니다
    /// - Parameters:
    ///   - baseSpacing: 기본 행간 (보통 설정 시 적용될 고정값)
    ///   - lineSpacing: 사용자의 행간 설정
    /// - Note: 공식 = baseSpacing * (lineSpacing.multiplier / 1.235)
    ///         1.235는 "보통" 설정의 multiplier로, 보통 설정 시 원래 baseSpacing을 유지
    public func dynamicLineSpacing(_ baseSpacing: CGFloat, lineSpacing: LineSpacing) -> some View {
        let spacing = baseSpacing * (lineSpacing.multiplier / 1.235)
        return self.lineSpacing(spacing)
    }
}
