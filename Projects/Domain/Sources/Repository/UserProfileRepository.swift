//
//  UserProfileRepository.swift
//  Domain
//
//  Created by 이승주 on 10/19/25.
//

import Foundation

public protocol UserProfileRepository {
    /// 사용자 프로필 저장
    func saveProfile(_ profile: UserProfile) async throws

    /// 사용자 프로필 가져오기
    func getProfile() async throws -> UserProfile?

    /// 온보딩 완료 여부 확인
    func hasCompletedOnboarding() async -> Bool
}
