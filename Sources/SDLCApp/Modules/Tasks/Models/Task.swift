import Foundation
import GRDB

public struct ProjectTask: Codable, FetchableRecord, PersistableRecord, TableRecord, Identifiable, Timestamped, SoftDeletable, Sendable {
    public static let databaseTableName = "tasks"
    
    public var id: UUID
    public var projectId: UUID
    public var requirementId: UUID?
    public var title: String
    public var description: String
    public var status: Status
    public var priority: Priority
    public var dueDate: Date?
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?
    
    public init(id: UUID = UUID(), projectId: UUID, requirementId: UUID? = nil, title: String, description: String, status: Status = .todo, priority: Priority = .medium, dueDate: Date? = nil, createdAt: Date = Date(), updatedAt: Date = Date(), deletedAt: Date? = nil) {
        self.id = id
        self.projectId = projectId
        self.requirementId = requirementId
        self.title = title
        self.description = description
        self.status = status
        self.priority = priority
        self.dueDate = dueDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}
