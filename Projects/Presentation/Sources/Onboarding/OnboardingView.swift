//
//  OnboardingView.swift
//  Presentation
//
//  Created by 이승주 on 10/19/25.
//

import SwiftUI
import Domain

public struct OnboardingView: View {
    @State private var nickname = ""
    @State private var selectedGender: UserProfile.Gender = .brother
    @State private var isSaving = false
    @State private var showError = false

    let saveUserProfileUseCase: SaveUserProfileUseCase
    let onComplete: () -> Void

    public init(
        saveUserProfileUseCase: SaveUserProfileUseCase,
        onComplete: @escaping () -> Void
    ) {
        self.saveUserProfileUseCase = saveUserProfileUseCase
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack {
            CrossSunsetBackground()
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // 타이틀
                VStack(spacing: 12) {
                    Text("환영합니다!")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(DS.Color.deepCocoa)

                    Text("큐튠과 함께 QT 여정을 시작하기 전에\n간단한 정보를 알려주세요")
                        .font(.system(size: 17))
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
                            Text("이름")
                                .font(DS.Font.titleM(.semibold))
                                .foregroundStyle(DS.Color.deepCocoa)
                        }

                        TextField("이름을 입력해주세요", text: $nickname)
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
                            Text("구분")
                                .font(DS.Font.titleM(.semibold))
                                .foregroundStyle(DS.Color.deepCocoa)
                        }

                        HStack(spacing: 12) {
                            // 형제 버튼
                            Button {
                                Haptics.tap()
                                selectedGender = .brother
                            } label: {
                                Text("형제")
                                    .font(DS.Font.bodyL(.semibold))
                                    .foregroundStyle(
                                        selectedGender == .brother
                                            ? .white
                                            : DS.Color.deepCocoa
                                    )
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: DS.Radius.s)
                                            .fill(
                                                selectedGender == .brother
                                                    ? DS.Color.mocha
                                                    : DS.Color.canvas
                                            )
                                    )
                            }
                            .buttonStyle(.plain)

                            // 자매 버튼
                            Button {
                                Haptics.tap()
                                selectedGender = .sister
                            } label: {
                                Text("자매")
                                    .font(DS.Font.bodyL(.semibold))
                                    .foregroundStyle(
                                        selectedGender == .sister
                                            ? .white
                                            : DS.Color.deepCocoa
                                    )
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: DS.Radius.s)
                                            .fill(
                                                selectedGender == .sister
                                                    ? DS.Color.mocha
                                                    : DS.Color.canvas
                                            )
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
                    saveProfile()
                } label: {
                    HStack(spacing: 8) {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("시작하기")
                                .font(.system(size: 17, weight: .bold))
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: nickname.isEmpty
                                        ? [DS.Color.textSecondary, DS.Color.textSecondary]
                                        : [DS.Color.mocha, DS.Color.deepCocoa],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(
                                color: nickname.isEmpty ? .clear : DS.Color.mocha.opacity(0.3),
                                radius: 8,
                                y: 4
                            )
                    )
                }
                .buttonStyle(.plain)
                .disabled(nickname.isEmpty || isSaving)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .alert("오류", isPresented: $showError) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("프로필 저장에 실패했습니다. 다시 시도해주세요.")
        }
    }

    private func saveProfile() {
        guard !nickname.isEmpty, !isSaving else { return }

        Task {
            await MainActor.run { isSaving = true }

            do {
                let profile = UserProfile(nickname: nickname, gender: selectedGender)
                try await saveUserProfileUseCase.execute(profile: profile)

                await MainActor.run {
                    Haptics.success()
                    isSaving = false
                    onComplete()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    showError = true
                }
            }
        }
    }
}
