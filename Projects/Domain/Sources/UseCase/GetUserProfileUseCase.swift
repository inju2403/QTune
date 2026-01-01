//
//  GetUserProfileUseCase.swift
//  Domain
//
//  Created by 이승주 on 10/19/25.
//

import Foundation

public protocol GetUserProfileUseCase {
    func execute() async throws -> UserProfile?
}

public final class DefaultGetUserProfileUseCase: GetUserProfileUseCase {
    private let repository: UserProfileRepository

    public init(repository: UserProfileRepository) {
        self.repository = repository
    }

    public func execute() async throws -> UserProfile? {
        try await repository.getProfile()
    }
}
