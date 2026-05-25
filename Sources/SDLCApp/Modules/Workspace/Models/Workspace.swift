import Foundation
import GRDB

public struct Workspace: Codable, FetchableRecord, PersistableRecord, TableRecord, Identifiable, Timestamped, SoftDeletable, Sendable {
    public static let databaseTableName = "workspaces"
    
    public var id: UUID
    public var name: String
    public var path: String
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?
    
    public init(id: UUID = UUID(), name: String, path: String, createdAt: Date = Date(), updatedAt: Date = Date(), deletedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.path = path
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}
