import Foundation
import GRDB

public protocol SearchRepositoryProtocol {
    func search(query: String, workspaceId: UUID) async throws -> [SearchItem]
}

public final class SearchRepository: SearchRepositoryProtocol, Sendable {
    private let searchService: SearchService

    public init(searchService: SearchService) {
        self.searchService = searchService
    }

    public func search(query: String, workspaceId: UUID) async throws -> [SearchItem] {
        try await searchService.search(query: query, workspaceId: workspaceId)
    }
}
