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
    @State private var viewModel: ProfileEditViewModel
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showImageSizeAlert = false

    public init(
        viewModel: ProfileEditViewModel
    ) {
        _viewModel = State(wrappedValue: viewModel)
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
                            .dsPageTitle()
                            .foregroundStyle(DS.Color.deepCocoa)

                        Text("프로필 정보를 변경할 수 있어요")
                            .dsBodyM()
                            .foregroundStyle(DS.Color.textSecondary)
                    }

                    // 프로필 이미지
                    profileImageSection()

                    // 입력 필드
                    inputSection()

                    // 저장 버튼
                    saveButton()
                    .padding(.top, 20)

                    Spacer()
                        .frame(height: 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationTitle("")
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
        }
        .overlay(alignment: .bottom) {
            if viewModel.state.showSaveSuccessToast {
                successToast()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(Motion.appear, value: viewModel.state.showSaveSuccessToast)
                    .onAppear {
                        Haptics.success()
                    }
            }
        }
        .onAppear {
            viewModel.onSaveComplete = {
                dismiss()
            }
        }
        .onTapGesture {
            self.endTextEditing()
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    // 10MB = 10 * 1024 * 1024 bytes
                    let maxSizeInBytes = 10 * 1024 * 1024
                    if data.count > maxSizeInBytes {
                        await MainActor.run {
                            showImageSizeAlert = true
                            selectedPhotoItem = nil
                        }
                    } else {
                        viewModel.send(.updateProfileImage(data))
                    }
                }
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
        .alert("이미지 크기 초과", isPresented: $showImageSizeAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("프로필 이미지는 10MB까지만 업로드할 수 있습니다.")
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
                if let imageData = viewModel.state.profileImageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
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
            if viewModel.state.profileImageData != nil {
                Button {
                    Haptics.tap()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.send(.updateProfileImage(nil))
                        selectedPhotoItem = nil
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 13))
                        Text("기본 이미지로 변경")
                            .dsSmall()
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
                        .dsTitleM(.semibold)
                        .foregroundStyle(DS.Color.deepCocoa)
                }

                TextField("이름을 입력하세요", text: Binding(
                    get: { viewModel.state.nickname },
                    set: { viewModel.send(.updateNickname($0)) }
                ))
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
                        .dsTitleM(.semibold)
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
                viewModel.send(.updateGender(gender))
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: viewModel.state.selectedGender == gender ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(viewModel.state.selectedGender == gender ? DS.Color.gold : DS.Color.textSecondary)
                    .font(.system(size: 20))

                Text(gender.rawValue)
                    .dsBodyL(.medium)
                    .foregroundStyle(viewModel.state.selectedGender == gender ? DS.Color.deepCocoa : DS.Color.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(viewModel.state.selectedGender == gender ? DS.Color.gold.opacity(0.1) : Color.white.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        viewModel.state.selectedGender == gender ? DS.Color.gold : DS.Color.divider,
                        lineWidth: viewModel.state.selectedGender == gender ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    func saveButton() -> some View {
        Button {
            guard !viewModel.state.isSaving && !viewModel.state.showSaveSuccessToast else { return }
            Haptics.tap()
            viewModel.send(.saveProfile)
        } label: {
            Text("저장")
                .dsBodyL(.bold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [DS.Color.gold.opacity(0.95), DS.Color.gold],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(
                            color: DS.Color.gold.opacity(0.3),
                            radius: 8,
                            y: 4
                        )
                )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    func successToast() -> some View {
        SoftCard {
            HStack(spacing: DS.Spacing.m) {
                ZStack {
                    Circle()
                        .fill(DS.Color.success.opacity(0.2))
                        .frame(width: 32, height: 32)
                        .blur(radius: 6)

                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(DS.Color.success)
                        .font(DS.Font.titleM())
                }

                Text("저장되었습니다")
                    .dsBodyM(.semibold)
                    .foregroundStyle(DS.Color.textPrimary)
            }
        }
        .padding(.horizontal, DS.Spacing.l)
        .padding(.bottom, DS.Spacing.xxl)
    }
}
