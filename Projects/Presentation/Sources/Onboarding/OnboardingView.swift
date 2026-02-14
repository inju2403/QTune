//
//  OnboardingView.swift
//  Presentation
//
//  Created by 이승주 on 10/19/25.
//

import SwiftUI
import Domain

public struct OnboardingView: View {
    @State private var viewModel: OnboardingViewModel

    public init(viewModel: OnboardingViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    public var body: some View {
        ZStack {
            CrossSunsetBackground()
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // 타이틀
                VStack(spacing: 12) {
                    DSText.hero("환영합니다!")
                        .foregroundStyle(DS.Color.deepCocoa)

                    DSText.bodyL("큐튠과 함께 QT 여정을 시작하기 전에\n간단한 정보를 알려주세요")
                        .foregroundStyle(DS.Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.bottom, 20)

                // 입력 카드
                VStack(alignment: .leading, spacing: 24) {
                    // 이름 입력
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.fill")
                                .foregroundStyle(DS.Color.gold)
                            DSText.titleM("이름", weight: .semibold)
                                .foregroundStyle(DS.Color.deepCocoa)
                        }

                        TextField("이름을 입력해주세요", text: Binding(
                            get: { viewModel.state.nickname },
                            set: { viewModel.send(.updateNickname($0)) }
                        ))
                            .font(DS.Font.bodyM())
                            .foregroundStyle(DS.Color.textPrimary)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: DS.Radius.s)
                                    .fill(DS.Color.canvas)
                            )
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                    }

                    // 성별 선택
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(DS.Color.gold)
                            DSText.titleM("구분", weight: .semibold)
                                .foregroundStyle(DS.Color.deepCocoa)
                        }

                        HStack(spacing: 12) {
                            // 형제 버튼
                            Button {
                                Haptics.tap()
                                viewModel.send(.selectGender(.brother))
                            } label: {
                                DSText.bodyL("형제", weight: .semibold)
                                    .foregroundStyle(
                                        viewModel.state.selectedGender == .brother
                                            ? .white
                                            : DS.Color.deepCocoa
                                    )
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: DS.Radius.s)
                                            .fill(
                                                viewModel.state.selectedGender == .brother
                                                    ? LinearGradient(
                                                        colors: [DS.Color.gold.opacity(0.95), DS.Color.gold],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                    : LinearGradient(
                                                        colors: [DS.Color.canvas, DS.Color.canvas],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                            )
                                    )
                                    .shadow(
                                        color: viewModel.state.selectedGender == .brother ? DS.Color.gold.opacity(0.3) : .clear,
                                        radius: 8,
                                        y: 4
                                    )
                            }
                            .buttonStyle(.plain)

                            // 자매 버튼
                            Button {
                                Haptics.tap()
                                viewModel.send(.selectGender(.sister))
                            } label: {
                                DSText.bodyL("자매", weight: .semibold)
                                    .foregroundStyle(
                                        viewModel.state.selectedGender == .sister
                                            ? .white
                                            : DS.Color.deepCocoa
                                    )
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: DS.Radius.s)
                                            .fill(
                                                viewModel.state.selectedGender == .sister
                                                    ? LinearGradient(
                                                        colors: [DS.Color.gold.opacity(0.95), DS.Color.gold],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                    : LinearGradient(
                                                        colors: [DS.Color.canvas, DS.Color.canvas],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                            )
                                    )
                                    .shadow(
                                        color: viewModel.state.selectedGender == .sister ? DS.Color.gold.opacity(0.3) : .clear,
                                        radius: 8,
                                        y: 4
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.l)
                        .fill(DS.Color.background)
                        .shadow(color: .black.opacity(0.1), radius: 12, y: 6)
                )
                .padding(.horizontal, 20)

                Spacer()

                // 시작하기 버튼
                Button {
                    Haptics.tap()
                    viewModel.send(.saveProfile)
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.state.isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            DSText.bodyL("시작하기", weight: .bold)
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: viewModel.state.nickname.isEmpty
                                        ? [DS.Color.textSecondary, DS.Color.textSecondary]
                                        : [DS.Color.gold.opacity(0.95), DS.Color.gold],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(
                                color: viewModel.state.nickname.isEmpty ? .clear : DS.Color.gold.opacity(0.3),
                                radius: 8,
                                y: 4
                            )
                    )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.state.nickname.isEmpty || viewModel.state.isSaving)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .onTapGesture {
            self.endTextEditing()
        }
        .onChange(of: viewModel.state.isSaving) { _, isSaving in
            if !isSaving && !viewModel.state.showError {
                Haptics.success()
            }
        }
        .alert("오류", isPresented: Binding(
            get: { viewModel.state.showError },
            set: { _ in }
        )) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("프로필 저장에 실패했습니다. 다시 시도해주세요.")
        }
    }
}
