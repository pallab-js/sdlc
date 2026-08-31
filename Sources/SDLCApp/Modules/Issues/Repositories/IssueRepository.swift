import Foundation
import GRDB

public protocol IssueRepositoryProtocol {
    func fetchAll(forProject projectId: UUID) async throws -> [Issue]
    func fetch(id: UUID) async throws -> Issue?
    func insert(_ issue: Issue) async throws
    func update(_ issue: Issue) async throws
    func delete(_ issue: Issue) async throws
}

public final class IssueRepository: IssueRepositoryProtocol, Sendable {
    private let dbQueue: DatabaseQueue
    
    public init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }
    
    public func fetchAll(forProject projectId: UUID) async throws -> [Issue] {
        try await dbQueue.read { db in
            try Issue
                .filter(Column("projectId") == projectId)
                .filter(Column("deletedAt") == nil)
                .order(Column("createdAt").desc)
                .fetchAll(db)
        }
    }
    
    public func fetch(id: UUID) async throws -> Issue? {
        try await dbQueue.read { db in
            try Issue
                .filter(Column("id") == id)
                .filter(Column("deletedAt") == nil)
                .fetchOne(db)
        }
    }
    
    public func insert(_ issue: Issue) async throws {
        let finalIssue = issue
        try await dbQueue.write { db in
            try finalIssue.insert(db)
        }
    }
    
    public func update(_ issue: Issue) async throws {
        var updated = issue
        updated.updatedAt = Date()
        let finalUpdated = updated
        try await dbQueue.write { db in
            try finalUpdated.update(db)
        }
    }
    
    public func delete(_ issue: Issue) async throws {
        var toDelete = issue
        toDelete.deletedAt = Date()
        let finalToDelete = toDelete
        try await dbQueue.write { db in
            try finalToDelete.update(db)
        }
    }
}
