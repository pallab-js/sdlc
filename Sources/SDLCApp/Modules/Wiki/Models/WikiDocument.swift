import Foundation
import GRDB

public struct WikiDocument: Codable, FetchableRecord, PersistableRecord, TableRecord, Identifiable, Timestamped, Sendable {
    public static let databaseTableName = "wiki_documents"
    
    public var id: UUID
    public var workspaceId: UUID
    public var title: String
    public var content: String
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(id: UUID = UUID(), workspaceId: UUID, title: String, content: String, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.workspaceId = workspaceId
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
