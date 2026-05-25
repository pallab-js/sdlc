import Foundation
import GRDB

public struct Project: Codable, FetchableRecord, PersistableRecord, TableRecord, Identifiable, Timestamped, SoftDeletable, Sendable {
    public static let databaseTableName = "projects"
    
    public var id: UUID
    public var workspaceId: UUID
    public var name: String
    public var description: String
    public var status: Status
    public var priority: Priority
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?
    
    public init(id: UUID = UUID(), workspaceId: UUID, name: String, description: String, status: Status = .todo, priority: Priority = .medium, createdAt: Date = Date(), updatedAt: Date = Date(), deletedAt: Date? = nil) {
        self.id = id
        self.workspaceId = workspaceId
        self.name = name
        self.description = description
        self.status = status
        self.priority = priority
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}

extension Project: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    public static func == (lhs: Project, rhs: Project) -> Bool {
        lhs.id == rhs.id
    }
}
