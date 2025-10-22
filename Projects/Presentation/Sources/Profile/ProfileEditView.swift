//
//  ProfileEditView.swift
//  Presentation
//
//  Created by 이승주 on 10/22/25.
//

import SwiftUI
import PhotosUI
import Domain

public struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var nickname: String
    @State private var selectedGender: UserProfile.Gender
    @State private var profileImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?

    let saveUseCase: SaveUserProfileUseCase
    let onSave: () -> Void

    public init(
        currentProfile: UserProfile?,
        saveUseCase: SaveUserProfileUseCase,
        onSave: @escaping () -> Void
    ) {
        _nickname = State(initialValue: currentProfile?.nickname ?? "")
        _selectedGender = State(initialValue: currentProfile?.gender ?? .brother)
        if let imageData = currentProfile?.profileImageData,
           let uiImage = UIImage(data: imageData) {
            _profileImage = State(initialValue: uiImage)
        }
        self.saveUseCase = saveUseCase
        self.onSave = onSave
    }

    public var body: some View {
        ZStack {
            CrossSunsetBackground()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 20)

                    // 헤더
                    VStack(spacing: 12) {
                        Text("프로필 수정")
                            .font(.system(size: 32, weight: .semibold, design: .rounded))
                            .foregroundStyle(DS.Color.deepCocoa)

                        Text("프로필 정보를 변경할 수 있어요")
                            .font(DS.Font.bodyM())
                            .foregroundStyle(DS.Color.textSecondary)
                    }

                    // 프로필 이미지
                    profileImageSection()

                    // 입력 필드
                    inputSection()

                    // 저장 버튼
                    PrimaryCTAButton(title: "저장", icon: "checkmark") {
                        Haptics.tap()
                        Task {
                            await saveProfile()
                        }
                    }
                    .padding(.top, 20)

                    Spacer()
                        .frame(height: 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedPhotoItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    profileImage = image
                }
            }
        }
    }
}

// MARK: - Subviews

private extension ProfileEditView {
    @ViewBuilder
    func profileImageSection() -> some View {
        VStack(spacing: 16) {
            // 이미지
            ZStack(alignment: .bottomTrailing) {
                if let image = profileImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(DS.Color.gold.opacity(0.3), lineWidth: 2)
                        )
                } else {
                    Circle()
                        .fill(DS.Color.gold.opacity(0.15))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(DS.Color.gold.opacity(0.5))
                        )
                        .overlay(
                            Circle()
                                .stroke(DS.Color.gold.opacity(0.3), lineWidth: 2)
                        )
                }

                // 사진 선택 버튼
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Circle()
                        .fill(DS.Color.gold)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.white)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                }
            }

            // 기본 이미지로 변경 버튼
            if profileImage != nil {
                Button {
                    Haptics.tap()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        profileImage = nil
                        selectedPhotoItem = nil
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 13))
                        Text("기본 이미지로 변경")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(DS.Color.textSecondary)
                }
            }
        }
    }

    @ViewBuilder
    func inputSection() -> some View {
        VStack(alignment: .leading, spacing: 24) {
            // 이름
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "person.text.rectangle")
                        .foregroundStyle(DS.Color.gold)
                        .font(.system(size: 18))
                    Text("이름")
                        .font(DS.Font.titleM(.semibold))
                        .foregroundStyle(DS.Color.deepCocoa)
                }

                TextField("이름을 입력하세요", text: $nickname)
                    .font(DS.Font.bodyL())
                    .foregroundStyle(DS.Color.textPrimary)
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.7))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(DS.Color.gold.opacity(0.2), lineWidth: 1)
                    )
            }

            // 형제/자매
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "person.2")
                        .foregroundStyle(DS.Color.gold)
                        .font(.system(size: 18))
                    Text("구분")
                        .font(DS.Font.titleM(.semibold))
                        .foregroundStyle(DS.Color.deepCocoa)
                }

                HStack(spacing: 12) {
                    genderButton(.brother)
                    genderButton(.sister)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.m)
                .fill(DS.Color.canvas.opacity(0.9))
        )
    }

    @ViewBuilder
    func genderButton(_ gender: UserProfile.Gender) -> some View {
        Button {
            Haptics.tap()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedGender = gender
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: selectedGender == gender ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selectedGender == gender ? DS.Color.gold : DS.Color.textSecondary)
                    .font(.system(size: 20))

                Text(gender.rawValue)
                    .font(DS.Font.bodyL(.medium))
                    .foregroundStyle(selectedGender == gender ? DS.Color.deepCocoa : DS.Color.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedGender == gender ? DS.Color.gold.opacity(0.1) : Color.white.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        selectedGender == gender ? DS.Color.gold : DS.Color.divider,
                        lineWidth: selectedGender == gender ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    func saveProfile() async {
        let imageData = profileImage?.jpegData(compressionQuality: 0.8)
        let profile = UserProfile(
            nickname: nickname,
            gender: selectedGender,
            profileImageData: imageData
        )

        do {
            try await saveUseCase.execute(profile: profile)
            Haptics.success()
            await MainActor.run {
                onSave()
                dismiss()
            }
        } catch {
            print("Failed to save profile: \(error)")
            Haptics.error()
        }
    }
}
