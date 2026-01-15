//
//  MyPageView.swift
//  Presentation
//
//  Created by 이승주 on 1/15/26.
//

import SwiftUI
import Domain

public struct MyPageView: View {
    @State private var viewModel: MyPageViewModel
    @Binding var userProfile: UserProfile?
    @State private var showProfileEdit = false
    @Environment(\.openURL) private var openURL

    let profileEditViewModelFactory: (UserProfile?) -> ProfileEditViewModel
    let getUserProfileUseCase: GetUserProfileUseCase

    public init(
        viewModel: MyPageViewModel,
        userProfile: Binding<UserProfile?>,
        profileEditViewModelFactory: @escaping (UserProfile?) -> ProfileEditViewModel,
        getUserProfileUseCase: GetUserProfileUseCase
    ) {
        _viewModel = State(wrappedValue: viewModel)
        _userProfile = userProfile
        self.profileEditViewModelFactory = profileEditViewModelFactory
        self.getUserProfileUseCase = getUserProfileUseCase
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                CrossSunsetBackground()

                List {
                    // 프로필 섹션
                    Section {
                        profileHeader()
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                    }

                    // 프로필 수정
                    Section {
                        menuRow(
                            icon: "person.crop.circle",
                            title: "프로필 수정",
                            action: { showProfileEdit = true }
                        )
                    }

                    // 큐튠 이야기
                    Section(header: sectionHeader("큐튠 이야기")) {
                        menuRow(
                            icon: "lightbulb",
                            title: "개선점 공유",
                            action: openImprovementForm
                        )
                        menuRow(
                            icon: "hand.thumbsup",
                            title: "칭찬하기",
                            action: openReview
                        )
                    }

                    // 앱 정보
                    Section(header: sectionHeader("앱 정보")) {
                        menuRow(
                            icon: "info.circle",
                            title: "버전 정보",
                            action: { viewModel.send(.tapVersionInfo) }
                        )
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("마이페이지")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showProfileEdit, onDismiss: {
                Task {
                    if let profile = try? await getUserProfileUseCase.execute() {
                        await MainActor.run {
                            userProfile = profile
                        }
                    }
                }
            }) {
                NavigationStack {
                    ProfileEditView(
                        viewModel: profileEditViewModelFactory(userProfile)
                    )
                }
            }
            .alert("버전 정보", isPresented: Binding(
                get: { viewModel.state.showVersionAlert },
                set: { if !$0 { viewModel.send(.dismissVersionAlert) } }
            )) {
                Button("확인", role: .cancel) {}
            } message: {
                Text("현재 버전: \(appVersion)")
            }
        }
    }
}

// MARK: - Subviews

private extension MyPageView {
    @ViewBuilder
    func profileHeader() -> some View {
        VStack(spacing: 16) {
            // 프로필 이미지
            if let imageData = userProfile?.profileImageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(DS.Color.gold.opacity(0.3), lineWidth: 2)
                    )
            } else {
                Circle()
                    .fill(DS.Color.gold.opacity(0.15))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(DS.Color.gold.opacity(0.5))
                    )
                    .overlay(
                        Circle()
                            .stroke(DS.Color.gold.opacity(0.3), lineWidth: 2)
                    )
            }

            // 이름 + 성별
            if let profile = userProfile {
                Text("\(profile.nickname) \(profile.gender.rawValue)님")
                    .font(DS.Font.titleL(.bold))
                    .foregroundStyle(DS.Color.deepCocoa)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    @ViewBuilder
    func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(DS.Font.caption(.semibold))
            .foregroundStyle(DS.Color.textSecondary)
    }

    @ViewBuilder
    func menuRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            Haptics.tap()
            action()
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(DS.Color.gold)
                    .frame(width: 24)

                Text(title)
                    .font(DS.Font.bodyL())
                    .foregroundStyle(DS.Color.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DS.Color.textSecondary)
            }
        }
    }

    func openImprovementForm() {
        guard let url = URL(string: "https://docs.google.com/forms/d/e/1FAIpQLSfzUt_GdAoPGt8ZjGOzsAdtgc6LAK1MPQc2Iu_6izpYB0OlrQ/viewform") else {
            assertionFailure("URL build failed")
            return
        }
        openURL(url)
    }

    func openReview() {
        guard let url = URL(string: "itms-apps://apps.apple.com/kr/app/id6757230938?action=write-review") else {
            assertionFailure("URL build failed")
            return
        }
        openURL(url)
    }

    var appVersion: String {
        // App Bundle에서 버전 정보 읽기
        guard let appBundle = Bundle.allBundles.first(where: { $0.bundleIdentifier == "com.inju.qtune" }),
              let version = appBundle.infoDictionary?["CFBundleShortVersionString"] as? String,
              let build = appBundle.infoDictionary?["CFBundleVersion"] as? String else {
            return "1.2.0 (120)"
        }
        return "\(version) (\(build))"
    }
}
