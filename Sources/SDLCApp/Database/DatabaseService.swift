import Foundation
import GRDB

public class DatabaseService {
    public let dbQueue: DatabaseQueue
    
    public init(inMemory: Bool = false, dbPath: String? = nil) {
        do {
            if inMemory {
                self.dbQueue = try DatabaseQueue()
            } else {
                let path: String
                if let dbPath = dbPath {
                    path = dbPath
                } else {
                    let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                    let appDirectory = appSupport.appendingPathComponent("SDLCApp", isDirectory: true)
                    try FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true, attributes: nil)
                    path = appDirectory.appendingPathComponent("sdlc.sqlite").path
                }
                self.dbQueue = try DatabaseQueue(path: path)
            }
            try setupMigrations()
        } catch {
            fatalError("Failed to initialize database: \(error)")
        }
    }
    
    private func setupMigrations() throws {
        var migrator = DatabaseMigrator()
        
        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif
        
        // 001: Workspaces
        migrator.registerMigration("createWorkspaces") { db in
            try db.create(table: "workspaces") { t in
                t.column("id", .text).primaryKey()
                t.column("name", .text).notNull()
                t.column("path", .text).notNull()
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
                t.column("deletedAt", .datetime)
            }
        }
        
        // 002: Projects
        migrator.registerMigration("createProjects") { db in
            try db.create(table: "projects") { t in
                t.column("id", .text).primaryKey()
                t.column("workspaceId", .text).notNull().references("workspaces", onDelete: .cascade)
                t.column("name", .text).notNull()
                t.column("description", .text).notNull()
                t.column("status", .text).notNull()
                t.column("priority", .text).notNull()
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
                t.column("deletedAt", .datetime)
            }
        }
        
        // 003: Requirements
        migrator.registerMigration("createRequirements") { db in
            try db.create(table: "requirements") { t in
                t.column("id", .text).primaryKey()
                t.column("workspaceId", .text).notNull().references("workspaces", onDelete: .cascade)
                t.column("title", .text).notNull()
                t.column("description", .text).notNull()
                t.column("status", .text).notNull()
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
                t.column("deletedAt", .datetime)
            }
        }
        
        // 004: Tasks
        migrator.registerMigration("createTasks") { db in
            try db.create(table: "tasks") { t in
                t.column("id", .text).primaryKey()
                t.column("projectId", .text).notNull().references("projects", onDelete: .cascade)
                t.column("requirementId", .text).references("requirements", onDelete: .setNull)
                t.column("title", .text).notNull()
                t.column("description", .text).notNull()
                t.column("status", .text).notNull()
                t.column("priority", .text).notNull()
                t.column("dueDate", .datetime)
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
                t.column("deletedAt", .datetime)
            }
        }
        
        // 005: Issues
        migrator.registerMigration("createIssues") { db in
            try db.create(table: "issues") { t in
                t.column("id", .text).primaryKey()
                t.column("projectId", .text).notNull().references("projects", onDelete: .cascade)
                t.column("title", .text).notNull()
                t.column("description", .text).notNull()
                t.column("status", .text).notNull()
                t.column("priority", .text).notNull()
                t.column("severity", .text).notNull()
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
                t.column("deletedAt", .datetime)
            }
        }
        
        // 006: Wiki Documents
        migrator.registerMigration("createWikiDocuments") { db in
            try db.create(table: "wiki_documents") { t in
                t.column("id", .text).primaryKey()
                t.column("workspaceId", .text).notNull().references("workspaces", onDelete: .cascade)
                t.column("title", .text).notNull()
                t.column("content", .text).notNull()
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }
        }
        
        // 007: Test Cases
        migrator.registerMigration("createTestCases") { db in
            try db.create(table: "test_cases") { t in
                t.column("id", .text).primaryKey()
                t.column("requirementId", .text).references("requirements", onDelete: .setNull)
                t.column("title", .text).notNull()
                t.column("description", .text).notNull()
                t.column("expectedResult", .text).notNull()
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }
        }
        
        // 008: Activity Logs
        migrator.registerMigration("createActivityLogs") { db in
            try db.create(table: "activity_logs") { t in
                t.column("id", .text).primaryKey()
                t.column("workspaceId", .text).notNull().references("workspaces", onDelete: .cascade)
                t.column("action", .text).notNull()
                t.column("entityType", .text).notNull()
                t.column("entityId", .text).notNull()
                t.column("details", .text).notNull()
                t.column("createdAt", .datetime).notNull()
            }
        }
        
        // 009: Attachments
        migrator.registerMigration("createAttachments") { db in
            try db.create(table: "attachments") { t in
                t.column("id", .text).primaryKey()
                t.column("entityType", .text).notNull()
                t.column("entityId", .text).notNull()
                t.column("filename", .text).notNull()
                t.column("filePath", .text).notNull()
                t.column("createdAt", .datetime).notNull()
            }
        }
        
        // 010: Sprints
        migrator.registerMigration("createSprints") { db in
            try db.create(table: "sprints") { t in
                t.column("id", .text).primaryKey()
                t.column("workspaceId", .text).notNull().references("workspaces", onDelete: .cascade)
                t.column("name", .text).notNull()
                t.column("startDate", .datetime).notNull()
                t.column("endDate", .datetime).notNull()
                t.column("status", .text).notNull()
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }
        }
        
        try migrator.migrate(self.dbQueue)
    }
}
