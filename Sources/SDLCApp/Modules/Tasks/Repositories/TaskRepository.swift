import Foundation
import GRDB

public protocol TaskRepositoryProtocol {
    func fetchAll(forProject projectId: UUID) async throws -> [Task]
    func fetch(id: UUID) async throws -> Task?
    func insert(_ task: Task) async throws
    func update(_ task: Task) async throws
    func delete(_ task: Task) async throws
}

public final class TaskRepository: TaskRepositoryProtocol, Sendable {
    private let dbQueue: DatabaseQueue
    
    public init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }
    
    public func fetchAll(forProject projectId: UUID) async throws -> [Task] {
        try await dbQueue.read { db in
            try Task
                .filter(Column("projectId") == projectId)
                .filter(Column("deletedAt") == nil)
                .order(Column("createdAt").desc)
                .fetchAll(db)
        }
    }
    
    public func fetch(id: UUID) async throws -> Task? {
        try await dbQueue.read { db in
            try Task.filter(Column("id") == id).fetchOne(db)
        }
    }
    
    public func insert(_ task: Task) async throws {
        let finalTask = task
        try await dbQueue.write { db in
            try finalTask.insert(db)
        }
    }
    
    public func update(_ task: Task) async throws {
        var updated = task
        updated.updatedAt = Date()
        let finalUpdated = updated
        try await dbQueue.write { db in
            try finalUpdated.update(db)
        }
    }
    
    public func delete(_ task: Task) async throws {
        var toDelete = task
        toDelete.deletedAt = Date()
        let finalToDelete = toDelete
        try await dbQueue.write { db in
            try finalToDelete.update(db)
        }
    }
}
