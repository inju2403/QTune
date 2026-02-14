//
//  DSComponents.swift
//  Presentation
//
//  Created by 이승주 on 2/11/26.
//

import SwiftUI
import Domain

// MARK: - DSText Component

/// Design System 텍스트 컴포넌트
/// 미리 정의된 스타일로 Text를 생성합니다
public struct DSText {

    // MARK: - Hero & Page Titles

    /// Hero 스타일 (40pt, rounded) - 온보딩용 대형 타이틀
    public static func hero(_ text: String, weight: Font.Weight = .bold) -> some View {
        Text(text).dsHero(weight)
    }

    /// Page Title 스타일 (32pt, rounded) - 페이지 타이틀
    public static func pageTitle(_ text: String, weight: Font.Weight = .semibold) -> some View {
        Text(text).dsPageTitle(weight)
    }

    // MARK: - Title Styles

    /// Title XL 스타일 (32pt, serif)
    public static func titleXL(_ text: String, weight: Font.Weight = .semibold) -> some View {
        Text(text).dsTitleXL(weight)
    }

    /// Title L 스타일 (28pt, serif)
    public static func titleL(_ text: String, weight: Font.Weight = .semibold) -> some View {
        Text(text).dsTitleL(weight)
    }

    /// Title M 스타일 (22pt, serif)
    public static func titleM(_ text: String, weight: Font.Weight = .semibold) -> some View {
        Text(text).dsTitleM(weight)
    }

    /// Title S 스타일 (19pt, serif)
    public static func titleS(_ text: String, weight: Font.Weight = .semibold) -> some View {
        Text(text).dsTitleS(weight)
    }

    // MARK: - Body Styles

    /// Body L 스타일 (17pt, default, 행간 6pt)
    public static func bodyL(_ text: String, weight: Font.Weight = .regular) -> some View {
        Text(text).dsBodyL(weight)
    }

    /// Body M 스타일 (15pt, default, 행간 4pt)
    public static func bodyM(_ text: String, weight: Font.Weight = .regular) -> some View {
        Text(text).dsBodyM(weight)
    }

    // MARK: - Label & Small Styles

    /// Label 스타일 (18pt, default) - 버튼, 라벨
    public static func label(_ text: String, weight: Font.Weight = .regular) -> some View {
        Text(text).dsLabel(weight)
    }

    /// Medium 스타일 (16pt, default) - 중간 크기 라벨
    public static func medium(_ text: String, weight: Font.Weight = .regular) -> some View {
        Text(text).dsMedium(weight)
    }

    /// Small 스타일 (14pt, default) - 작은 라벨
    public static func small(_ text: String, weight: Font.Weight = .medium) -> some View {
        Text(text).dsSmall(weight)
    }

    /// Caption 스타일 (13pt, default, 행간 3pt)
    public static func caption(_ text: String, weight: Font.Weight = .medium) -> some View {
        Text(text).dsCaption(weight)
    }

    // MARK: - Special Styles

    /// Verse 스타일 (커스텀 사이즈, serif, 행간 5pt) - 성경 구절용
    public static func verse(_ text: String, size: CGFloat = 17, weight: Font.Weight = .regular) -> some View {
        Text(text).dsVerse(size, weight)
    }

    /// QT List Title 스타일 (21pt, serif, bold)
    public static func qtListTitle(_ text: String) -> some View {
        Text(text).dsQTListTitle()
    }

    /// Share Card Text 스타일 (38pt, bold, 행간 18pt)
    public static func shareText(_ text: String) -> some View {
        Text(text).dsShareText()
    }

    // MARK: - LocalizedStringKey Support

    /// Hero 스타일 - LocalizedStringKey 지원
    public static func hero(_ text: LocalizedStringKey, weight: Font.Weight = .bold) -> some View {
        Text(text).dsHero(weight)
    }

    /// Body L 스타일 - LocalizedStringKey 지원
    public static func bodyL(_ text: LocalizedStringKey, weight: Font.Weight = .regular) -> some View {
        Text(text).dsBodyL(weight)
    }

    /// Body M 스타일 - LocalizedStringKey 지원
    public static func bodyM(_ text: LocalizedStringKey, weight: Font.Weight = .regular) -> some View {
        Text(text).dsBodyM(weight)
    }

    /// Caption 스타일 - LocalizedStringKey 지원
    public static func caption(_ text: LocalizedStringKey, weight: Font.Weight = .medium) -> some View {
        Text(text).dsCaption(weight)
    }
}

// MARK: - DSTextEditor Component

/// Design System TextEditor 컴포넌트
/// 미리 정의된 스타일로 TextEditor를 생성합니다
public struct DSTextEditor {

    /// 기본 Editor 스타일 (16pt, rounded, 행간 5pt)
    public static func editor(
        text: Binding<String>,
        placeholder: String? = nil
    ) -> some View {
        ScaledTextEditor(
            text: text,
            size: 16,
            weight: .regular,
            design: .rounded,
            placeholder: placeholder
        )
    }

    /// Body 스타일 Editor (15pt, default)
    public static func body(
        text: Binding<String>,
        placeholder: String? = nil
    ) -> some View {
        ScaledTextEditor(
            text: text,
            size: 15,
            weight: .regular,
            design: .default,
            placeholder: placeholder
        )
    }

    /// Large 스타일 Editor (17pt, default)
    public static func large(
        text: Binding<String>,
        placeholder: String? = nil
    ) -> some View {
        ScaledTextEditor(
            text: text,
            size: 17,
            weight: .regular,
            design: .default,
            placeholder: placeholder
        )
    }

    /// Serif 스타일 Editor (16pt, serif) - 성경/묵상용
    public static func serif(
        text: Binding<String>,
        placeholder: String? = nil,
        size: CGFloat = 16
    ) -> some View {
        ScaledTextEditor(
            text: text,
            size: size,
            weight: .regular,
            design: .serif,
            placeholder: placeholder
        )
    }

    /// Custom 스타일 Editor - 완전 커스터마이즈
    public static func custom(
        text: Binding<String>,
        size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .default,
        placeholder: String? = nil
    ) -> some View {
        ScaledTextEditor(
            text: text,
            size: size,
            weight: weight,
            design: design,
            placeholder: placeholder
        )
    }
}

// MARK: - Usage Examples

/*
 사용 예시:

 // 기존 방식
 Text("Hello").dsBodyL()
 Text("Title").dsTitleM(.bold)

 // 새로운 방식
 DSText.bodyL("Hello")
 DSText.titleM("Title", weight: .bold)

 // TextEditor
 DSTextEditor.editor(text: $myText, placeholder: "내용을 입력하세요")
 DSTextEditor.serif(text: $verseText, size: 18)
 */