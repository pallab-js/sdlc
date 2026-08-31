import Foundation
import GRDB

public protocol RequirementRepositoryProtocol {
    func fetchAll(forWorkspace workspaceId: UUID) async throws -> [Requirement]
    func fetch(id: UUID) async throws -> Requirement?
    func insert(_ requirement: Requirement) async throws
    func update(_ requirement: Requirement) async throws
    func delete(_ requirement: Requirement) async throws
}

public final class RequirementRepository: RequirementRepositoryProtocol, Sendable {
    private let dbQueue: DatabaseQueue
    
    public init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }
    
    public func fetchAll(forWorkspace workspaceId: UUID) async throws -> [Requirement] {
        try await dbQueue.read { db in
            try Requirement
                .filter(Column("workspaceId") == workspaceId)
                .filter(Column("deletedAt") == nil)
                .order(Column("createdAt").desc)
                .fetchAll(db)
        }
    }
    
    public func fetch(id: UUID) async throws -> Requirement? {
        try await dbQueue.read { db in
            try Requirement
                .filter(Column("id") == id)
                .filter(Column("deletedAt") == nil)
                .fetchOne(db)
        }
    }
    
    public func insert(_ requirement: Requirement) async throws {
        let finalRequirement = requirement
        try await dbQueue.write { db in
            try finalRequirement.insert(db)
        }
    }
    
    public func update(_ requirement: Requirement) async throws {
        var updated = requirement
        updated.updatedAt = Date()
        let finalUpdated = updated
        try await dbQueue.write { db in
            try finalUpdated.update(db)
        }
    }
    
    public func delete(_ requirement: Requirement) async throws {
        var toDelete = requirement
        toDelete.deletedAt = Date()
        let finalToDelete = toDelete
        try await dbQueue.write { db in
            try finalToDelete.update(db)
        }
    }
}
