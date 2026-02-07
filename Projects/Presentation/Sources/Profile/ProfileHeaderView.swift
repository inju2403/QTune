//
//  ProfileHeaderView.swift
//  Presentation
//
//  Created by 이승주 on 10/22/25.
//

import SwiftUI
import Domain

/// 헤더에 표시할 프로필 이미지 + 이름
public struct ProfileHeaderView: View {
    let profile: UserProfile?
    let onTap: () -> Void

    public init(profile: UserProfile?, onTap: @escaping () -> Void) {
        self.profile = profile
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                // 프로필 이미지
                if let imageData = profile?.profileImageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(DS.Color.gold.opacity(0.3), lineWidth: 1.5)
                        )
                } else {
                    // 기본 아이콘
                    Circle()
                        .fill(DS.Color.gold.opacity(0.15))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(DS.Color.gold)
                        )
                        .overlay(
                            Circle()
                                .stroke(DS.Color.gold.opacity(0.3), lineWidth: 1.5)
                        )
                }

                // 이름
                if let profile = profile {
                    Text(profile.nickname)
                        .dsBodyM(.semibold)
                        .foregroundStyle(DS.Color.deepCocoa)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
