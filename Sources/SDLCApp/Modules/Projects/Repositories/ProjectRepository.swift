import Foundation
import GRDB

public protocol ProjectRepositoryProtocol {
    func fetchAll(forWorkspace workspaceId: UUID) async throws -> [Project]
    func fetch(id: UUID) async throws -> Project?
    func insert(_ project: Project) async throws
    func update(_ project: Project) async throws
    func delete(_ project: Project) async throws
}

public final class ProjectRepository: ProjectRepositoryProtocol, Sendable {
    private let dbQueue: DatabaseQueue
    
    public init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }
    
    public func fetchAll(forWorkspace workspaceId: UUID) async throws -> [Project] {
        try await dbQueue.read { db in
            try Project
                .filter(Column("workspaceId") == workspaceId)
                .filter(Column("deletedAt") == nil)
                .order(Column("createdAt").desc)
                .fetchAll(db)
        }
    }
    
    public func fetch(id: UUID) async throws -> Project? {
        try await dbQueue.read { db in
            try Project
                .filter(Column("id") == id)
                .filter(Column("deletedAt") == nil)
                .fetchOne(db)
        }
    }
    
    public func insert(_ project: Project) async throws {
        let finalProject = project
        try await dbQueue.write { db in
            try finalProject.insert(db)
        }
    }
    
    public func update(_ project: Project) async throws {
        var updated = project
        updated.updatedAt = Date()
        let finalUpdated = updated
        try await dbQueue.write { db in
            try finalUpdated.update(db)
        }
    }
    
    public func delete(_ project: Project) async throws {
        var toDelete = project
        toDelete.deletedAt = Date()
        let finalToDelete = toDelete
        try await dbQueue.write { db in
            try finalToDelete.update(db)
        }
    }
}
