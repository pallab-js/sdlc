import Foundation
import GRDB

public struct Issue: Codable, FetchableRecord, PersistableRecord, TableRecord, Identifiable, Timestamped, SoftDeletable, Sendable {
    public static let databaseTableName = "issues"
    
    public var id: UUID
    public var projectId: UUID
    public var title: String
    public var description: String
    public var status: Status
    public var priority: Priority
    public var severity: Severity
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?
    
    public init(id: UUID = UUID(), projectId: UUID, title: String, description: String, status: Status = .todo, priority: Priority = .medium, severity: Severity = .medium, createdAt: Date = Date(), updatedAt: Date = Date(), deletedAt: Date? = nil) {
        self.id = id
        self.projectId = projectId
        self.title = title
        self.description = description
        self.status = status
        self.priority = priority
        self.severity = severity
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}
