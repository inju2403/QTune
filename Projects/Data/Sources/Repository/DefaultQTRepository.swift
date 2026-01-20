//
//  DefaultQTRepository.swift
//  Data
//
//  Created by 이승주 on 10/12/25.
//

import Foundation
import SwiftData
import Domain

/// QT 저장소 기본 구현체 (SwiftData 기반)
@available(iOS 17, *)
public final class DefaultQTRepository: QTRepository {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - QTRepository Implementation

    public func commit(_ draft: QuietTime, session: UserSession) async throws -> QuietTime {
        let model = QTEntryModel.fromDomain(draft)
        model.status = "committed"
        model.updatedAt = Date()

        modelContext.insert(model)
        try modelContext.save()

        return model.toDomain()
    }

    public func fetchList(query: QTQuery, session: UserSession) async throws -> [QuietTime] {
        let descriptor = FetchDescriptor<QTEntryModel>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        let models = try modelContext.fetch(descriptor)

        // 필터링
        var filtered = models.filter { $0.status == "committed" }

        if let isFavorite = query.isFavorite {
            filtered = filtered.filter { $0.isFavorite == isFavorite }
        }

        if let dateRange = query.dateRange {
            filtered = filtered.filter {
                $0.createdAt >= dateRange.start && $0.createdAt <= dateRange.end
            }
        }

        // 검색 필터링
        if let searchText = query.searchText, !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            filtered = filtered.filter { model in
                let matchesVerse = model.verseRef.lowercased().contains(searchLower)
                let matchesKorean = (model.korean ?? "").lowercased().contains(searchLower)
                let matchesRationale = (model.rationale ?? "").lowercased().contains(searchLower)
                let matchesTags = model.tags.contains { $0.lowercased().contains(searchLower) }

                var matchesTemplate = false
                if model.template == "SOAP" {
                    matchesTemplate = [model.soapObservation, model.soapApplication, model.soapPrayer]
                        .compactMap { $0 }
                        .contains { $0.lowercased().contains(searchLower) }
                } else {
                    matchesTemplate = [model.actsAdoration, model.actsConfession, model.actsThanksgiving, model.actsSupplication]
                        .compactMap { $0 }
                        .contains { $0.lowercased().contains(searchLower) }
                }

                return matchesVerse || matchesKorean || matchesRationale || matchesTags || matchesTemplate
            }
        }

        // 페이지네이션
        let paged = Array(filtered
            .dropFirst(query.offset)
            .prefix(query.limit))

        return paged.map { $0.toDomain() }
    }

    public func get(id: UUID, session: UserSession) async throws -> QuietTime {
        let targetId = id
        let descriptor = FetchDescriptor<QTEntryModel>(
            predicate: #Predicate<QTEntryModel> { model in
                model.id == targetId
            }
        )

        guard let model = try modelContext.fetch(descriptor).first else {
            throw DomainError.notFound
        }

        return model.toDomain()
    }

    public func updateMemo(id: UUID, newMemo: String, session: UserSession) async throws -> QuietTime {
        let targetId = id
        let descriptor = FetchDescriptor<QTEntryModel>(
            predicate: #Predicate<QTEntryModel> { model in
                model.id == targetId
            }
        )

        guard let model = try modelContext.fetch(descriptor).first else {
            throw DomainError.notFound
        }

        // Note: memo는 deprecated이므로 여기서는 업데이트하지 않음
        model.updatedAt = Date()
        try modelContext.save()

        return model.toDomain()
    }

    public func toggleFavorite(id: UUID, session: UserSession) async throws -> Bool {
        let targetId = id
        let descriptor = FetchDescriptor<QTEntryModel>(
            predicate: #Predicate<QTEntryModel> { model in
                model.id == targetId
            }
        )

        guard let model = try modelContext.fetch(descriptor).first else {
            throw DomainError.notFound
        }

        model.isFavorite.toggle()
        model.updatedAt = Date()
        try modelContext.save()

        return model.isFavorite
    }

    // MARK: - Additional Methods (템플릿 필드 업데이트)

    /// QT 전체 업데이트 (템플릿 필드 포함)
    public func update(_ qt: QuietTime, session: UserSession) async throws -> QuietTime {
        let targetId = qt.id
        let descriptor = FetchDescriptor<QTEntryModel>(
            predicate: #Predicate<QTEntryModel> { model in
                model.id == targetId
            }
        )

        guard let model = try modelContext.fetch(descriptor).first else {
            throw DomainError.notFound
        }

        model.updateFrom(qt)
        try modelContext.save()

        return model.toDomain()
    }

    /// QT 삭제
    public func delete(id: UUID, session: UserSession) async throws {
        let targetId = id
        let descriptor = FetchDescriptor<QTEntryModel>(
            predicate: #Predicate<QTEntryModel> { model in
                model.id == targetId
            }
        )

        guard let model = try modelContext.fetch(descriptor).first else {
            throw DomainError.notFound
        }

        modelContext.delete(model)
        try modelContext.save()
    }
}
