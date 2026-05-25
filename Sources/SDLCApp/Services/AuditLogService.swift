import Foundation
import GRDB

public struct ActivityLog: Codable, FetchableRecord, PersistableRecord, TableRecord, Identifiable, Sendable {
    public static let databaseTableName = "activity_logs"
    
    public var id: UUID
    public var workspaceId: UUID
    public var action: String
    public var entityType: String
    public var entityId: String
    public var details: String
    public var createdAt: Date
    
    public init(id: UUID = UUID(), workspaceId: UUID, action: String, entityType: String, entityId: String, details: String, createdAt: Date = Date()) {
        self.id = id
        self.workspaceId = workspaceId
        self.action = action
        self.entityType = entityType
        self.entityId = entityId
        self.details = details
        self.createdAt = createdAt
    }
}

public final class AuditLogService: Sendable {
    private let dbQueue: DatabaseQueue
    
    public init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }
    
    public func log(workspaceId: UUID, action: String, entityType: String, entityId: UUID, details: String) async throws {
        let entry = ActivityLog(workspaceId: workspaceId, action: action, entityType: entityType, entityId: entityId.uuidString, details: details)
        try await dbQueue.write { db in
            try entry.insert(db)
        }
    }
    
    public func fetchLogs(forWorkspace workspaceId: UUID) async throws -> [ActivityLog] {
        try await dbQueue.read { db in
            try ActivityLog
                .filter(Column("workspaceId") == workspaceId)
                .order(Column("createdAt").desc)
                .fetchAll(db)
        }
    }
}
