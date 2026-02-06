//
//  FontModifiers.swift
//  Presentation
//
//  Created by 이승주 on 2/6/26.
//

import SwiftUI
import Domain

// MARK: - Font Style ViewModifiers

/// Title XL 스타일 (34pt, serif, 행간 없음)
struct DSTitleXLModifier: ViewModifier {
    @Environment(\.fontScale) var fontScale

    let weight: Font.Weight

    func body(content: Content) -> some View {
        let baseSize: CGFloat = 34
        let scaledSize = baseSize * fontScale.multiplier

        content
            .font(.system(size: scaledSize, weight: weight, design: .serif))
    }
}

/// Title L 스타일 (28pt, serif, 행간 없음)
struct DSTitleLModifier: ViewModifier {
    @Environment(\.fontScale) var fontScale

    let weight: Font.Weight

    func body(content: Content) -> some View {
        let baseSize: CGFloat = 28
        let scaledSize = baseSize * fontScale.multiplier

        content
            .font(.system(size: scaledSize, weight: weight, design: .serif))
    }
}

/// Title M 스타일 (22pt, serif, 행간 없음)
struct DSTitleMModifier: ViewModifier {
    @Environment(\.fontScale) var fontScale

    let weight: Font.Weight

    func body(content: Content) -> some View {
        let baseSize: CGFloat = 22
        let scaledSize = baseSize * fontScale.multiplier

        content
            .font(.system(size: scaledSize, weight: weight, design: .serif))
    }
}

/// Title S 스타일 (19pt, serif, 행간 없음)
struct DSTitleSModifier: ViewModifier {
    @Environment(\.fontScale) var fontScale

    let weight: Font.Weight

    func body(content: Content) -> some View {
        let baseSize: CGFloat = 19
        let scaledSize = baseSize * fontScale.multiplier

        content
            .font(.system(size: scaledSize, weight: weight, design: .serif))
    }
}

/// Body L 스타일 (17pt, default, 행간 6pt)
struct DSBodyLModifier: ViewModifier {
    @Environment(\.fontScale) var fontScale
    @Environment(\.lineSpacing) var lineSpacing

    let weight: Font.Weight

    func body(content: Content) -> some View {
        content
            .font(.system(size: 17 * fontScale.multiplier, weight: weight, design: .default))
            .dynamicLineSpacing(6, lineSpacing: lineSpacing)
    }
}

/// Body M 스타일 (15pt, default, 행간 4pt)
struct DSBodyMModifier: ViewModifier {
    @Environment(\.fontScale) var fontScale
    @Environment(\.lineSpacing) var lineSpacing

    let weight: Font.Weight

    func body(content: Content) -> some View {
        content
            .font(.system(size: 15 * fontScale.multiplier, weight: weight, design: .default))
            .dynamicLineSpacing(4, lineSpacing: lineSpacing)
    }
}

/// Caption 스타일 (13pt, default, 행간 3pt)
struct DSCaptionModifier: ViewModifier {
    @Environment(\.fontScale) var fontScale
    @Environment(\.lineSpacing) var lineSpacing

    let weight: Font.Weight

    func body(content: Content) -> some View {
        content
            .font(.system(size: 13 * fontScale.multiplier, weight: weight, design: .default))
            .dynamicLineSpacing(3, lineSpacing: lineSpacing)
    }
}

/// Verse 스타일 (커스텀 사이즈, serif, 행간 5pt)
struct DSVerseModifier: ViewModifier {
    @Environment(\.fontScale) var fontScale
    @Environment(\.lineSpacing) var lineSpacing

    let size: CGFloat
    let weight: Font.Weight

    func body(content: Content) -> some View {
        content
            .font(.system(size: size * fontScale.multiplier, weight: weight, design: .serif))
            .dynamicLineSpacing(5, lineSpacing: lineSpacing)
    }
}

/// QT List Title 스타일 (21pt, serif, bold, 행간 없음)
struct DSQTListTitleModifier: ViewModifier {
    @Environment(\.fontScale) var fontScale

    func body(content: Content) -> some View {
        content
            .font(.system(size: 21 * fontScale.multiplier, weight: .bold, design: .serif))
    }
}

/// Editor Text 스타일 (16pt, rounded, 행간 5pt) - TextEditor용
struct DSEditorTextModifier: ViewModifier {
    @Environment(\.fontScale) var fontScale
    @Environment(\.lineSpacing) var lineSpacing

    let weight: Font.Weight

    func body(content: Content) -> some View {
        content
            .font(.system(size: 16 * fontScale.multiplier, weight: weight, design: .rounded))
            .dynamicLineSpacing(5, lineSpacing: lineSpacing)
    }
}

/// Share Card Text 스타일 (38pt, default, bold, 행간 18pt)
struct DSShareTextModifier: ViewModifier {
    @Environment(\.fontScale) var fontScale
    @Environment(\.lineSpacing) var lineSpacing

    func body(content: Content) -> some View {
        content
            .font(.system(size: 38 * fontScale.multiplier, weight: .bold))
            .dynamicLineSpacing(18, lineSpacing: lineSpacing)
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

    /// Verse 스타일 적용 (커스텀 사이즈, serif, 행간 5pt)
    public func dsVerse(_ size: CGFloat = 17, _ weight: Font.Weight = .regular) -> some View {
        modifier(DSVerseModifier(size: size, weight: weight))
    }

    /// QT List Title 스타일 적용 (21pt, serif, bold)
    public func dsQTListTitle() -> some View {
        modifier(DSQTListTitleModifier())
    }

    /// Editor Text 스타일 적용 (16pt, rounded)
    public func dsEditorText(_ weight: Font.Weight = .regular) -> some View {
        modifier(DSEditorTextModifier(weight: weight))
    }

    /// Share Card Text 스타일 적용 (38pt, bold, 행간 18pt)
    public func dsShareText() -> some View {
        modifier(DSShareTextModifier())
    }
}

// MARK: - Scaled TextEditor Component

/// 폰트 크기가 자동 조절되는 TextEditor
/// - Parameters:
///   - text: 바인딩된 텍스트
///   - size: 기본 폰트 크기
///   - weight: 폰트 두께
///   - design: 폰트 디자인 (.default, .rounded, .serif)
public struct ScaledTextEditor: View {
    @Binding var text: String
    let size: CGFloat
    let weight: Font.Weight
    let design: Font.Design

    @Environment(\.fontScale) private var fontScale

    public init(
        text: Binding<String>,
        size: CGFloat = 16,
        weight: Font.Weight = .regular,
        design: Font.Design = .default
    ) {
        self._text = text
        self.size = size
        self.weight = weight
        self.design = design
    }

    public var body: some View {
        TextEditor(text: $text)
            .font(.system(
                size: size * fontScale.multiplier,
                weight: weight,
                design: design
            ))
    }
}
