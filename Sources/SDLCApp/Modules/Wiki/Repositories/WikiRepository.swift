import Foundation
import GRDB

public protocol WikiRepositoryProtocol {
    func fetchAll(forWorkspace workspaceId: UUID) async throws -> [WikiDocument]
    func fetch(id: UUID) async throws -> WikiDocument?
    func insert(_ document: WikiDocument) async throws
    func update(_ document: WikiDocument) async throws
    func delete(_ document: WikiDocument) async throws
}

public final class WikiRepository: WikiRepositoryProtocol, Sendable {
    private let dbQueue: DatabaseQueue
    
    public init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }
    
    public func fetchAll(forWorkspace workspaceId: UUID) async throws -> [WikiDocument] {
        try await dbQueue.read { db in
            try WikiDocument
                .filter(Column("workspaceId") == workspaceId)
                .order(Column("createdAt").desc)
                .fetchAll(db)
        }
    }
    
    public func fetch(id: UUID) async throws -> WikiDocument? {
        try await dbQueue.read { db in
            try WikiDocument.filter(Column("id") == id).fetchOne(db)
        }
    }
    
    public func insert(_ document: WikiDocument) async throws {
        let finalDoc = document
        try await dbQueue.write { db in
            try finalDoc.insert(db)
        }
    }
    
    public func update(_ document: WikiDocument) async throws {
        var updated = document
        updated.updatedAt = Date()
        let finalUpdated = updated
        try await dbQueue.write { db in
            try finalUpdated.update(db)
        }
    }
    
    public func delete(_ document: WikiDocument) async throws {
        let finalDoc = document
        try await dbQueue.write { db in
            _ = try finalDoc.delete(db)
        }
    }
}
