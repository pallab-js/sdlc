import Foundation
import GRDB

public protocol WorkspaceRepositoryProtocol {
    func fetchAll() async throws -> [Workspace]
    func fetch(id: UUID) async throws -> Workspace?
    func insert(_ workspace: Workspace) async throws
    func update(_ workspace: Workspace) async throws
    func delete(_ workspace: Workspace) async throws
}

public final class WorkspaceRepository: WorkspaceRepositoryProtocol, Sendable {
    private let dbQueue: DatabaseQueue
    
    public init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }
    
    public func fetchAll() async throws -> [Workspace] {
        try await dbQueue.read { db in
            try Workspace
                .filter(Column("deletedAt") == nil)
                .order(Column("createdAt").desc)
                .fetchAll(db)
        }
    }
    
    public func fetch(id: UUID) async throws -> Workspace? {
        try await dbQueue.read { db in
            try Workspace.filter(Column("id") == id).fetchOne(db)
        }
    }
    
    public func insert(_ workspace: Workspace) async throws {
        let finalWorkspace = workspace
        try await dbQueue.write { db in
            try finalWorkspace.insert(db)
        }
    }
    
    public func update(_ workspace: Workspace) async throws {
        var updated = workspace
        updated.updatedAt = Date()
        let finalUpdated = updated
        try await dbQueue.write { db in
            try finalUpdated.update(db)
        }
    }
    
    public func delete(_ workspace: Workspace) async throws {
        var toDelete = workspace
        toDelete.deletedAt = Date()
        let finalToDelete = toDelete
        try await dbQueue.write { db in
            try finalToDelete.update(db)
        }
    }
}
