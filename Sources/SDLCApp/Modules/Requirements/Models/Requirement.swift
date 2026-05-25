import Foundation
import GRDB

public struct Requirement: Codable, FetchableRecord, PersistableRecord, TableRecord, Identifiable, Timestamped, SoftDeletable, Sendable {
    public static let databaseTableName = "requirements"
    
    public var id: UUID
    public var workspaceId: UUID
    public var title: String
    public var description: String
    public var status: String
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?
    
    public init(id: UUID = UUID(), workspaceId: UUID, title: String, description: String, status: String = "DRAFT", createdAt: Date = Date(), updatedAt: Date = Date(), deletedAt: Date? = nil) {
        self.id = id
        self.workspaceId = workspaceId
        self.title = title
        self.description = description
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}
