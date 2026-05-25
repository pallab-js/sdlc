import Foundation
import GRDB

public final class SearchService: Sendable {
    private let dbQueue: DatabaseQueue
    
    public init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }
    
    private static func extractUUID(from row: Row, column: String) -> UUID? {
        if let uuid: UUID = row[column] { return uuid }
        if let str: String = row[column], let uuid = UUID(uuidString: str) { return uuid }
        return nil
    }

    public func search(query: String, workspaceId: UUID) async throws -> [SearchItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return []
        }
        
        let searchPattern = "%\(trimmed)%"
        
        return try await dbQueue.read { db in
            var items = [SearchItem]()
            
            // Search projects
            let projects = try Row.fetchAll(db, sql: """
                SELECT id, name, description FROM projects 
                WHERE workspaceId = ? AND deletedAt IS NULL AND (name LIKE ? OR description LIKE ?)
            """, arguments: [workspaceId, searchPattern, searchPattern])
            for row in projects {
                if let id = Self.extractUUID(from: row, column: "id") {
                    items.append(SearchItem(id: id, type: "Project", title: row["name"], snippet: row["description"]))
                }
            }
            
            // Search tasks
            let tasks = try Row.fetchAll(db, sql: """
                SELECT t.id, t.title, t.description 
                FROM tasks t INNER JOIN projects p ON t.projectId = p.id
                WHERE p.workspaceId = ? AND t.deletedAt IS NULL AND (t.title LIKE ? OR t.description LIKE ?)
            """, arguments: [workspaceId, searchPattern, searchPattern])
            for row in tasks {
                if let id = Self.extractUUID(from: row, column: "id") {
                    items.append(SearchItem(id: id, type: "Task", title: row["title"], snippet: row["description"]))
                }
            }
            
            // Search requirements
            let requirements = try Row.fetchAll(db, sql: """
                SELECT id, title, description FROM requirements
                WHERE workspaceId = ? AND deletedAt IS NULL AND (title LIKE ? OR description LIKE ?)
            """, arguments: [workspaceId, searchPattern, searchPattern])
            for row in requirements {
                if let id = Self.extractUUID(from: row, column: "id") {
                    items.append(SearchItem(id: id, type: "Requirement", title: row["title"], snippet: row["description"]))
                }
            }
            
            // Search issues
            let issues = try Row.fetchAll(db, sql: """
                SELECT i.id, i.title, i.description
                FROM issues i INNER JOIN projects p ON i.projectId = p.id
                WHERE p.workspaceId = ? AND i.deletedAt IS NULL AND (i.title LIKE ? OR i.description LIKE ?)
            """, arguments: [workspaceId, searchPattern, searchPattern])
            for row in issues {
                if let id = Self.extractUUID(from: row, column: "id") {
                    items.append(SearchItem(id: id, type: "Issue", title: row["title"], snippet: row["description"]))
                }
            }
            
            // Search wiki documents
            let wikiDocs = try Row.fetchAll(db, sql: """
                SELECT id, title, content FROM wiki_documents
                WHERE workspaceId = ? AND (title LIKE ? OR content LIKE ?)
            """, arguments: [workspaceId, searchPattern, searchPattern])
            for row in wikiDocs {
                if let id = Self.extractUUID(from: row, column: "id") {
                    let snippet = (row["content"] as String).prefix(200).description
                    items.append(SearchItem(id: id, type: "Wiki", title: row["title"], snippet: snippet))
                }
            }
            
            // Search test cases (via requirements join for workspace)
            let testCases = try Row.fetchAll(db, sql: """
                SELECT tc.id, tc.title, tc.description
                FROM test_cases tc LEFT JOIN requirements r ON tc.requirementId = r.id
                WHERE r.workspaceId = ? AND (tc.title LIKE ? OR tc.description LIKE ?)
            """, arguments: [workspaceId, searchPattern, searchPattern])
            for row in testCases {
                if let id = Self.extractUUID(from: row, column: "id") {
                    items.append(SearchItem(id: id, type: "Test Case", title: row["title"], snippet: row["description"]))
                }
            }
            
            return items
        }
    }
}
