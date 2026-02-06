//
//  FontSettingsView.swift
//  Presentation
//
//  Created by 이승주 on 2/6/26.
//

import SwiftUI
import Domain

public struct FontSettingsView: View {
    @State private var viewModel: FontSettingsViewModel
    @Binding var userProfile: UserProfile?
    @Environment(\.dismiss) private var dismiss

    let onSave: (FontScale, LineSpacing) -> Void

    public init(
        viewModel: FontSettingsViewModel,
        userProfile: Binding<UserProfile?>,
        onSave: @escaping (FontScale, LineSpacing) -> Void
    ) {
        _viewModel = State(wrappedValue: viewModel)
        _userProfile = userProfile
        self.onSave = onSave
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                CrossSunsetBackground()

                ScrollView {
                    VStack(spacing: DS.Spacing.xl) {
                        // 미리보기 섹션
                        previewSection()

                        // 폰트 크기 섹션
                        fontScaleSection()

                        // 행간 섹션
                        lineSpacingSection()
                    }
                    .padding(DS.Spacing.l)
                }
            }
            .navigationTitle("폰트 설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        Haptics.tap()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        Haptics.tap()
                        saveSettings()
                    }
                    .font(DS.Font.bodyL(.semibold))
                    .foregroundStyle(DS.Color.gold)
                }
            }
        }
    }
}

// MARK: - Subviews
private extension FontSettingsView {
    @ViewBuilder
    func previewSection() -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            Text("미리보기")
                .font(DS.Font.titleM(.semibold))
                .foregroundStyle(DS.Color.deepCocoa)

            Text("하나님이 세상을 이처럼 사랑하사\n독생자를 주셨으니 이는 그를 믿는 자마다\n멸망하지 않고 영생을 얻게 하려 하심이라")
                .modifier(DSBodyLModifier(weight: .regular))
                .environment(\.fontScale, viewModel.state.selectedFontScale)
                .environment(\.lineSpacing, viewModel.state.selectedLineSpacing)
                .foregroundStyle(DS.Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(DS.Spacing.m)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.m)
                        .fill(DS.Color.canvas)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.m)
                        .stroke(DS.Color.gold.opacity(0.2), lineWidth: 1)
                )
        }
    }

    @ViewBuilder
    func fontScaleSection() -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            Text("폰트 크기")
                .font(DS.Font.titleM(.semibold))
                .foregroundStyle(DS.Color.deepCocoa)

            HStack(spacing: DS.Spacing.s) {
                ForEach(FontScale.allCases, id: \.self) { scale in
                    fontScaleButton(scale)
                }
            }
        }
    }

    @ViewBuilder
    func fontScaleButton(_ scale: FontScale) -> some View {
        let isSelected = viewModel.state.selectedFontScale == scale

        Button {
            Haptics.tap()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.send(.selectFontScale(scale))
            }
        } label: {
            Text(scale.displayName)
                .font(DS.Font.bodyM(.semibold))
                .foregroundStyle(isSelected ? .white : DS.Color.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Spacing.m)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.s)
                        .fill(isSelected ? DS.Color.gold : DS.Color.canvas)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.s)
                        .stroke(
                            isSelected ? DS.Color.gold : DS.Color.stroke,
                            lineWidth: isSelected ? 2 : 1
                        )
                )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    func lineSpacingSection() -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            Text("행간")
                .font(DS.Font.titleM(.semibold))
                .foregroundStyle(DS.Color.deepCocoa)

            HStack(spacing: DS.Spacing.s) {
                ForEach(LineSpacing.allCases, id: \.self) { spacing in
                    lineSpacingButton(spacing)
                }
            }
        }
    }

    @ViewBuilder
    func lineSpacingButton(_ spacing: LineSpacing) -> some View {
        let isSelected = viewModel.state.selectedLineSpacing == spacing

        Button {
            Haptics.tap()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.send(.selectLineSpacing(spacing))
            }
        } label: {
            Text(spacing.displayName)
                .font(DS.Font.bodyM(.semibold))
                .foregroundStyle(isSelected ? .white : DS.Color.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Spacing.m)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.s)
                        .fill(isSelected ? DS.Color.olive : DS.Color.canvas)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.s)
                        .stroke(
                            isSelected ? DS.Color.olive : DS.Color.stroke,
                            lineWidth: isSelected ? 2 : 1
                        )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions
    func saveSettings() {
        onSave(
            viewModel.state.selectedFontScale,
            viewModel.state.selectedLineSpacing
        )
        dismiss()
    }
}
