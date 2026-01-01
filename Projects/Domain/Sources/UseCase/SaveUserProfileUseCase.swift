//
//  SaveUserProfileUseCase.swift
//  Domain
//
//  Created by 이승주 on 10/19/25.
//

import Foundation

public protocol SaveUserProfileUseCase {
    func execute(profile: UserProfile) async throws
}

public final class DefaultSaveUserProfileUseCase: SaveUserProfileUseCase {
    private let repository: UserProfileRepository

    public init(repository: UserProfileRepository) {
        self.repository = repository
    }

    public func execute(profile: UserProfile) async throws {
        try await repository.saveProfile(profile)
    }
}
