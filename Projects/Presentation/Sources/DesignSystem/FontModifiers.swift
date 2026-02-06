//
//  FontModifiers.swift
//  Presentation
//
//  Created by 이승주 on 2/6/26.
//

import SwiftUI
import Domain

// MARK: - Font Style ViewModifiers

/// Title XL 스타일 (34pt, serif)
struct DSTitleXLModifier: ViewModifier {
    @Environment(\.fontScale) var fontScale
    @Environment(\.lineSpacing) var lineSpacing

    let weight: Font.Weight

    func body(content: Content) -> some View {
        let baseSize: CGFloat = 34
        let scaledSize = baseSize * fontScale.multiplier

        content
            .font(.system(size: scaledSize, weight: weight, design: .serif))
            .dynamicLineSpacing(scaledSize, lineSpacing: lineSpacing)
    }
}

/// Title L 스타일 (28pt, serif)
struct DSTitleLModifier: ViewModifier {
    @Environment(\.fontScale) var fontScale
    @Environment(\.lineSpacing) var lineSpacing

    let weight: Font.Weight

    func body(content: Content) -> some View {
        let baseSize: CGFloat = 28
        let scaledSize = baseSize * fontScale.multiplier

        content
            .font(.system(size: scaledSize, weight: weight, design: .serif))
            .dynamicLineSpacing(scaledSize, lineSpacing: lineSpacing)
    }
}

/// Title M 스타일 (22pt, serif)
struct DSTitleMModifier: ViewModifier {
    @Environment(\.fontScale) var fontScale
    @Environment(\.lineSpacing) var lineSpacing

    let weight: Font.Weight

    func body(content: Content) -> some View {
        let baseSize: CGFloat = 22
        let scaledSize = baseSize * fontScale.multiplier

        content
            .font(.system(size: scaledSize, weight: weight, design: .serif))
            .dynamicLineSpacing(scaledSize, lineSpacing: lineSpacing)
    }
}

/// Title S 스타일 (19pt, serif)
struct DSTitleSModifier: ViewModifier {
    @Environment(\.fontScale) var fontScale
    @Environment(\.lineSpacing) var lineSpacing

    let weight: Font.Weight

    func body(content: Content) -> some View {
        let baseSize: CGFloat = 19
        let scaledSize = baseSize * fontScale.multiplier

        content
            .font(.system(size: scaledSize, weight: weight, design: .serif))
            .dynamicLineSpacing(scaledSize, lineSpacing: lineSpacing)
    }
}

/// Body L 스타일 (17pt, default)
struct DSBodyLModifier: ViewModifier {
    @Environment(\.fontScale) var fontScale
    @Environment(\.lineSpacing) var lineSpacing

    let weight: Font.Weight

    func body(content: Content) -> some View {
        let baseSize: CGFloat = 17
        let scaledSize = baseSize * fontScale.multiplier

        content
            .font(.system(size: scaledSize, weight: weight, design: .default))
            .dynamicLineSpacing(scaledSize, lineSpacing: lineSpacing)
    }
}

/// Body M 스타일 (15pt, default)
struct DSBodyMModifier: ViewModifier {
    @Environment(\.fontScale) var fontScale
    @Environment(\.lineSpacing) var lineSpacing

    let weight: Font.Weight

    func body(content: Content) -> some View {
        let baseSize: CGFloat = 15
        let scaledSize = baseSize * fontScale.multiplier

        content
            .font(.system(size: scaledSize, weight: weight, design: .default))
            .dynamicLineSpacing(scaledSize, lineSpacing: lineSpacing)
    }
}

/// Caption 스타일 (13pt, default)
struct DSCaptionModifier: ViewModifier {
    @Environment(\.fontScale) var fontScale
    @Environment(\.lineSpacing) var lineSpacing

    let weight: Font.Weight

    func body(content: Content) -> some View {
        let baseSize: CGFloat = 13
        let scaledSize = baseSize * fontScale.multiplier

        content
            .font(.system(size: scaledSize, weight: weight, design: .default))
            .dynamicLineSpacing(scaledSize, lineSpacing: lineSpacing)
    }
}

/// Verse 스타일 (커스텀 사이즈, serif)
struct DSVerseModifier: ViewModifier {
    @Environment(\.fontScale) var fontScale
    @Environment(\.lineSpacing) var lineSpacing

    let size: CGFloat
    let weight: Font.Weight

    func body(content: Content) -> some View {
        let scaledSize = size * fontScale.multiplier

        content
            .font(.system(size: scaledSize, weight: weight, design: .serif))
            .dynamicLineSpacing(scaledSize, lineSpacing: lineSpacing)
    }
}

// MARK: - Text Extensions

extension Text {
    /// Title XL 스타일 적용 (34pt, serif)
    public func dsTitleXL(_ weight: Font.Weight = .semibold) -> some View {
        modifier(DSTitleXLModifier(weight: weight))
    }

    /// Title L 스타일 적용 (28pt, serif)
    public func dsTitleL(_ weight: Font.Weight = .semibold) -> some View {
        modifier(DSTitleLModifier(weight: weight))
    }

    /// Title M 스타일 적용 (22pt, serif)
    public func dsTitleM(_ weight: Font.Weight = .semibold) -> some View {
        modifier(DSTitleMModifier(weight: weight))
    }

    /// Title S 스타일 적용 (19pt, serif)
    public func dsTitleS(_ weight: Font.Weight = .semibold) -> some View {
        modifier(DSTitleSModifier(weight: weight))
    }

    /// Body L 스타일 적용 (17pt, default)
    public func dsBodyL(_ weight: Font.Weight = .regular) -> some View {
        modifier(DSBodyLModifier(weight: weight))
    }

    /// Body M 스타일 적용 (15pt, default)
    public func dsBodyM(_ weight: Font.Weight = .regular) -> some View {
        modifier(DSBodyMModifier(weight: weight))
    }

    /// Caption 스타일 적용 (13pt, default)
    public func dsCaption(_ weight: Font.Weight = .medium) -> some View {
        modifier(DSCaptionModifier(weight: weight))
    }

    /// Verse 스타일 적용 (커스텀 사이즈, serif)
    public func dsVerse(_ size: CGFloat = 17, _ weight: Font.Weight = .regular) -> some View {
        modifier(DSVerseModifier(size: size, weight: weight))
    }
}
