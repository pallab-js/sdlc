import Foundation
import GRDB

public struct TestCase: Codable, FetchableRecord, PersistableRecord, TableRecord, Identifiable, Timestamped, SoftDeletable, Sendable {
    public static let databaseTableName = "test_cases"
    
    public var id: UUID
    public var requirementId: UUID?
    public var title: String
    public var description: String
    public var expectedResult: String
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?
    
    public init(id: UUID = UUID(), requirementId: UUID? = nil, title: String, description: String, expectedResult: String, createdAt: Date = Date(), updatedAt: Date = Date(), deletedAt: Date? = nil) {
        self.id = id
        self.requirementId = requirementId
        self.title = title
        self.description = description
        self.expectedResult = expectedResult
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}
