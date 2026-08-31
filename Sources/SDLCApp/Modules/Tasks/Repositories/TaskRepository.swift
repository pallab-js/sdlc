import Foundation
import GRDB

public protocol ProjectTaskRepositoryProtocol {
    func fetchAll(forProject projectId: UUID) async throws -> [ProjectTask]
    func fetch(id: UUID) async throws -> ProjectTask?
    func insert(_ task: ProjectTask) async throws
    func update(_ task: ProjectTask) async throws
    func delete(_ task: ProjectTask) async throws
}

public final class ProjectTaskRepository: ProjectTaskRepositoryProtocol, Sendable {
    private let dbQueue: DatabaseQueue
    
    public init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }
    
    public func fetchAll(forProject projectId: UUID) async throws -> [ProjectTask] {
        try await dbQueue.read { db in
            try ProjectTask
                .filter(Column("projectId") == projectId)
                .filter(Column("deletedAt") == nil)
                .order(Column("createdAt").desc)
                .fetchAll(db)
        }
    }
    
    public func fetch(id: UUID) async throws -> ProjectTask? {
        try await dbQueue.read { db in
            try ProjectTask
                .filter(Column("id") == id)
                .filter(Column("deletedAt") == nil)
                .fetchOne(db)
        }
    }
    
    public func insert(_ task: ProjectTask) async throws {
        let finalTask = task
        try await dbQueue.write { db in
            try finalTask.insert(db)
        }
    }
    
    public func update(_ task: ProjectTask) async throws {
        var updated = task
        updated.updatedAt = Date()
        let finalUpdated = updated
        try await dbQueue.write { db in
            try finalUpdated.update(db)
        }
    }
    
    public func delete(_ task: ProjectTask) async throws {
        var toDelete = task
        toDelete.deletedAt = Date()
        let finalToDelete = toDelete
        try await dbQueue.write { db in
            try finalToDelete.update(db)
        }
    }
}
