import Foundation
import GRDB

public final class SearchService: Sendable {
    private let dbQueue: DatabaseQueue
    
    public init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }
    
    public func search(query: String, workspaceId: UUID) async throws -> [SearchItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        
        let ftsQuery = trimmed
            .replacingOccurrences(of: "'", with: "''")
        
        return try await dbQueue.read { db in
            var items = [SearchItem]()
            
            let projects = try Row.fetchAll(db, sql: """
                SELECT p.id, p.name, p.description
                FROM projects p
                INNER JOIN projects_fts fts ON p.rowid = fts.rowid
                WHERE projects_fts MATCH ? AND p.workspaceId = ? AND p.deletedAt IS NULL
                ORDER BY rank
            """, arguments: [ftsQuery, workspaceId])
            for row in projects {
                if let id: UUID = row["id"] {
                    items.append(SearchItem(id: id, type: "Project", title: row["name"], snippet: row["description"]))
                }
            }
            
            let tasks = try Row.fetchAll(db, sql: """
                SELECT t.id, t.title, t.description
                FROM tasks t
                INNER JOIN projects p ON t.projectId = p.id
                INNER JOIN tasks_fts fts ON t.rowid = fts.rowid
                WHERE tasks_fts MATCH ? AND p.workspaceId = ? AND t.deletedAt IS NULL
                ORDER BY rank
            """, arguments: [ftsQuery, workspaceId])
            for row in tasks {
                if let id: UUID = row["id"] {
                    items.append(SearchItem(id: id, type: "Task", title: row["title"], snippet: row["description"]))
                }
            }
            
            let requirements = try Row.fetchAll(db, sql: """
                SELECT r.id, r.title, r.description
                FROM requirements r
                INNER JOIN requirements_fts fts ON r.rowid = fts.rowid
                WHERE requirements_fts MATCH ? AND r.workspaceId = ? AND r.deletedAt IS NULL
                ORDER BY rank
            """, arguments: [ftsQuery, workspaceId])
            for row in requirements {
                if let id: UUID = row["id"] {
                    items.append(SearchItem(id: id, type: "Requirement", title: row["title"], snippet: row["description"]))
                }
            }
            
            let issues = try Row.fetchAll(db, sql: """
                SELECT i.id, i.title, i.description
                FROM issues i
                INNER JOIN projects p ON i.projectId = p.id
                INNER JOIN issues_fts fts ON i.rowid = fts.rowid
                WHERE issues_fts MATCH ? AND p.workspaceId = ? AND i.deletedAt IS NULL
                ORDER BY rank
            """, arguments: [ftsQuery, workspaceId])
            for row in issues {
                if let id: UUID = row["id"] {
                    items.append(SearchItem(id: id, type: "Issue", title: row["title"], snippet: row["description"]))
                }
            }
            
            let wikiDocs = try Row.fetchAll(db, sql: """
                SELECT w.id, w.title, w.content
                FROM wiki_documents w
                INNER JOIN wiki_documents_fts fts ON w.rowid = fts.rowid
                WHERE wiki_documents_fts MATCH ? AND w.workspaceId = ?
                ORDER BY rank
            """, arguments: [ftsQuery, workspaceId])
            for row in wikiDocs {
                if let id: UUID = row["id"] {
                    let snippet = (row["content"] as String).prefix(200).description
                    items.append(SearchItem(id: id, type: "Wiki", title: row["title"], snippet: snippet))
                }
            }
            
            let testCases = try Row.fetchAll(db, sql: """
                SELECT tc.id, tc.title, tc.description
                FROM test_cases tc
                INNER JOIN requirements r ON tc.requirementId = r.id
                INNER JOIN test_cases_fts fts ON tc.rowid = fts.rowid
                WHERE test_cases_fts MATCH ? AND r.workspaceId = ? AND tc.deletedAt IS NULL
                ORDER BY rank
            """, arguments: [ftsQuery, workspaceId])
            for row in testCases {
                if let id: UUID = row["id"] {
                    items.append(SearchItem(id: id, type: "Test Case", title: row["title"], snippet: row["description"]))
                }
            }
            
            return items
        }
    }
    
    public func reindexAll() async throws {
        try await dbQueue.write { db in
            try db.execute(sql: "DELETE FROM projects_fts")
            try db.execute(sql: "DELETE FROM tasks_fts")
            try db.execute(sql: "DELETE FROM requirements_fts")
            try db.execute(sql: "DELETE FROM issues_fts")
            try db.execute(sql: "DELETE FROM wiki_documents_fts")
            try db.execute(sql: "DELETE FROM test_cases_fts")
            
            try db.execute(sql: """
                INSERT INTO projects_fts(rowid, id, title, content)
                SELECT rowid, id, name, description FROM projects WHERE deletedAt IS NULL
            """)
            try db.execute(sql: """
                INSERT INTO tasks_fts(rowid, id, title, content)
                SELECT rowid, id, title, description FROM tasks WHERE deletedAt IS NULL
            """)
            try db.execute(sql: """
                INSERT INTO requirements_fts(rowid, id, title, content)
                SELECT rowid, id, title, description FROM requirements WHERE deletedAt IS NULL
            """)
            try db.execute(sql: """
                INSERT INTO issues_fts(rowid, id, title, content)
                SELECT rowid, id, title, description FROM issues WHERE deletedAt IS NULL
            """)
            try db.execute(sql: """
                INSERT INTO wiki_documents_fts(rowid, id, title, content)
                SELECT rowid, id, title, content FROM wiki_documents
            """)
            try db.execute(sql: """
                INSERT INTO test_cases_fts(rowid, id, title, content)
                SELECT rowid, id, title, description FROM test_cases WHERE deletedAt IS NULL
            """)
        }
    }
}
