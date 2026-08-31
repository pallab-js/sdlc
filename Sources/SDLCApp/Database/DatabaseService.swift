import Foundation
import GRDB

public enum DatabaseError: Error, LocalizedError {
    case initializationFailed(Error)
    
    public var errorDescription: String? {
        switch self {
        case .initializationFailed(let underlying):
            return "Failed to initialize database: \(underlying.localizedDescription)"
        }
    }
}

public class DatabaseService {
    public let dbQueue: DatabaseQueue
    
    public init(inMemory: Bool = false, dbPath: String? = nil) throws {
        if inMemory {
            self.dbQueue = try DatabaseQueue()
        } else {
            let path: String
            if let dbPath = dbPath {
                path = dbPath
            } else {
                guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
                    throw DatabaseError.initializationFailed(
                        NSError(domain: "DatabaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot locate Application Support directory"])
                    )
                }
                let appDirectory = appSupport.appendingPathComponent("SDLCApp", isDirectory: true)
                try FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true, attributes: nil)
                path = appDirectory.appendingPathComponent("sdlc.sqlite").path
            }
            self.dbQueue = try DatabaseQueue(path: path)
        }
        try setupMigrations()
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
        
        // 011: Add deletedAt to wiki_documents
        migrator.registerMigration("addWikiDocumentsSoftDelete") { db in
            try db.alter(table: "wiki_documents") { t in
                t.add(column: "deletedAt", .datetime)
            }
        }
        
        // 012: Add deletedAt to test_cases for soft-delete support
        migrator.registerMigration("addTestCasesSoftDelete") { db in
            try db.alter(table: "test_cases") { t in
                t.add(column: "deletedAt", .datetime)
            }
        }
        
        // 013: Performance indexes
        migrator.registerMigration("addPerformanceIndexes") { db in
            try db.create(index: "idx_projects_workspaceId", on: "projects", columns: ["workspaceId"])
            try db.create(index: "idx_projects_deletedAt", on: "projects", columns: ["deletedAt"])
            try db.create(index: "idx_tasks_projectId", on: "tasks", columns: ["projectId"])
            try db.create(index: "idx_tasks_status", on: "tasks", columns: ["status"])
            try db.create(index: "idx_tasks_deletedAt", on: "tasks", columns: ["deletedAt"])
            try db.create(index: "idx_requirements_workspaceId", on: "requirements", columns: ["workspaceId"])
            try db.create(index: "idx_requirements_deletedAt", on: "requirements", columns: ["deletedAt"])
            try db.create(index: "idx_issues_projectId", on: "issues", columns: ["projectId"])
            try db.create(index: "idx_issues_status", on: "issues", columns: ["status"])
            try db.create(index: "idx_issues_deletedAt", on: "issues", columns: ["deletedAt"])
            try db.create(index: "idx_wiki_documents_workspaceId", on: "wiki_documents", columns: ["workspaceId"])
            try db.create(index: "idx_activity_logs_workspaceId", on: "activity_logs", columns: ["workspaceId"])
            try db.create(index: "idx_activity_logs_createdAt", on: "activity_logs", columns: ["createdAt"])
            try db.create(index: "idx_test_cases_requirementId", on: "test_cases", columns: ["requirementId"])
            try db.create(index: "idx_attachments_entityType_entityId", on: "attachments", columns: ["entityType", "entityId"])
            try db.create(index: "idx_sprints_workspaceId", on: "sprints", columns: ["workspaceId"])
        }
        
        // 014: FTS5 full-text search virtual tables
        migrator.registerMigration("addFTS5SearchTables") { db in
            try db.execute(sql: """
                CREATE VIRTUAL TABLE IF NOT EXISTS projects_fts USING fts5(
                    id, title, content, content=projects, content_rowid=rowid
                )
            """)
            try db.execute(sql: """
                CREATE VIRTUAL TABLE IF NOT EXISTS tasks_fts USING fts5(
                    id, title, content, content=tasks, content_rowid=rowid
                )
            """)
            try db.execute(sql: """
                CREATE VIRTUAL TABLE IF NOT EXISTS requirements_fts USING fts5(
                    id, title, content, content=requirements, content_rowid=rowid
                )
            """)
            try db.execute(sql: """
                CREATE VIRTUAL TABLE IF NOT EXISTS issues_fts USING fts5(
                    id, title, content, content=issues, content_rowid=rowid
                )
            """)
            try db.execute(sql: """
                CREATE VIRTUAL TABLE IF NOT EXISTS wiki_documents_fts USING fts5(
                    id, title, content, content=wiki_documents, content_rowid=rowid
                )
            """)
            try db.execute(sql: """
                CREATE VIRTUAL TABLE IF NOT EXISTS test_cases_fts USING fts5(
                    id, title, content, content=test_cases, content_rowid=rowid
                )
            """)
        }
        
        // 015: Populate FTS indexes from existing data
        migrator.registerMigration("populateFTSIndexes") { db in
            // Projects FTS
            try db.execute(sql: """
                INSERT INTO projects_fts(rowid, id, title, content)
                SELECT rowid, id, name, description FROM projects WHERE deletedAt IS NULL
            """)
            // Tasks FTS
            try db.execute(sql: """
                INSERT INTO tasks_fts(rowid, id, title, content)
                SELECT rowid, id, title, description FROM tasks WHERE deletedAt IS NULL
            """)
            // Requirements FTS
            try db.execute(sql: """
                INSERT INTO requirements_fts(rowid, id, title, content)
                SELECT rowid, id, title, description FROM requirements WHERE deletedAt IS NULL
            """)
            // Issues FTS
            try db.execute(sql: """
                INSERT INTO issues_fts(rowid, id, title, content)
                SELECT rowid, id, title, description FROM issues WHERE deletedAt IS NULL
            """)
            // Wiki documents FTS
            try db.execute(sql: """
                INSERT INTO wiki_documents_fts(rowid, id, title, content)
                SELECT rowid, id, title, content FROM wiki_documents
            """)
            // Test cases FTS
            try db.execute(sql: """
                INSERT INTO test_cases_fts(rowid, id, title, content)
                SELECT rowid, id, title, description FROM test_cases WHERE deletedAt IS NULL
            """)
        }
        
        // 016: FTS sync triggers for automatic index updates
        migrator.registerMigration("addFTSSyncTriggers") { db in
            // Projects triggers
            try db.execute(sql: """
                CREATE TRIGGER projects_ai AFTER INSERT ON projects BEGIN
                    INSERT INTO projects_fts(rowid, id, title, content)
                    VALUES (new.rowid, new.id, new.name, new.description);
                END
            """)
            try db.execute(sql: """
                CREATE TRIGGER projects_ad AFTER DELETE ON projects BEGIN
                    INSERT INTO projects_fts(projects_fts, rowid, id, title, content)
                    VALUES ('delete', old.rowid, old.id, old.name, old.description);
                END
            """)
            try db.execute(sql: """
                CREATE TRIGGER projects_au AFTER UPDATE ON projects BEGIN
                    INSERT INTO projects_fts(projects_fts, rowid, id, title, content)
                    VALUES ('delete', old.rowid, old.id, old.name, old.description);
                    INSERT INTO projects_fts(rowid, id, title, content)
                    VALUES (new.rowid, new.id, new.name, new.description);
                END
            """)
            
            // Tasks triggers
            try db.execute(sql: """
                CREATE TRIGGER tasks_ai AFTER INSERT ON tasks BEGIN
                    INSERT INTO tasks_fts(rowid, id, title, content)
                    VALUES (new.rowid, new.id, new.title, new.description);
                END
            """)
            try db.execute(sql: """
                CREATE TRIGGER tasks_ad AFTER DELETE ON tasks BEGIN
                    INSERT INTO tasks_fts(tasks_fts, rowid, id, title, content)
                    VALUES ('delete', old.rowid, old.id, old.title, old.description);
                END
            """)
            try db.execute(sql: """
                CREATE TRIGGER tasks_au AFTER UPDATE ON tasks BEGIN
                    INSERT INTO tasks_fts(tasks_fts, rowid, id, title, content)
                    VALUES ('delete', old.rowid, old.id, old.title, old.description);
                    INSERT INTO tasks_fts(rowid, id, title, content)
                    VALUES (new.rowid, new.id, new.title, new.description);
                END
            """)
            
            // Requirements triggers
            try db.execute(sql: """
                CREATE TRIGGER requirements_ai AFTER INSERT ON requirements BEGIN
                    INSERT INTO requirements_fts(rowid, id, title, content)
                    VALUES (new.rowid, new.id, new.title, new.description);
                END
            """)
            try db.execute(sql: """
                CREATE TRIGGER requirements_ad AFTER DELETE ON requirements BEGIN
                    INSERT INTO requirements_fts(requirements_fts, rowid, id, title, content)
                    VALUES ('delete', old.rowid, old.id, old.title, old.description);
                END
            """)
            try db.execute(sql: """
                CREATE TRIGGER requirements_au AFTER UPDATE ON requirements BEGIN
                    INSERT INTO requirements_fts(requirements_fts, rowid, id, title, content)
                    VALUES ('delete', old.rowid, old.id, old.title, old.description);
                    INSERT INTO requirements_fts(rowid, id, title, content)
                    VALUES (new.rowid, new.id, new.title, new.description);
                END
            """)
            
            // Issues triggers
            try db.execute(sql: """
                CREATE TRIGGER issues_ai AFTER INSERT ON issues BEGIN
                    INSERT INTO issues_fts(rowid, id, title, content)
                    VALUES (new.rowid, new.id, new.title, new.description);
                END
            """)
            try db.execute(sql: """
                CREATE TRIGGER issues_ad AFTER DELETE ON issues BEGIN
                    INSERT INTO issues_fts(issues_fts, rowid, id, title, content)
                    VALUES ('delete', old.rowid, old.id, old.title, old.description);
                END
            """)
            try db.execute(sql: """
                CREATE TRIGGER issues_au AFTER UPDATE ON issues BEGIN
                    INSERT INTO issues_fts(issues_fts, rowid, id, title, content)
                    VALUES ('delete', old.rowid, old.id, old.title, old.description);
                    INSERT INTO issues_fts(rowid, id, title, content)
                    VALUES (new.rowid, new.id, new.title, new.description);
                END
            """)
            
            // Wiki documents triggers
            try db.execute(sql: """
                CREATE TRIGGER wiki_documents_ai AFTER INSERT ON wiki_documents BEGIN
                    INSERT INTO wiki_documents_fts(rowid, id, title, content)
                    VALUES (new.rowid, new.id, new.title, new.content);
                END
            """)
            try db.execute(sql: """
                CREATE TRIGGER wiki_documents_ad AFTER DELETE ON wiki_documents BEGIN
                    INSERT INTO wiki_documents_fts(wiki_documents_fts, rowid, id, title, content)
                    VALUES ('delete', old.rowid, old.id, old.title, old.content);
                END
            """)
            try db.execute(sql: """
                CREATE TRIGGER wiki_documents_au AFTER UPDATE ON wiki_documents BEGIN
                    INSERT INTO wiki_documents_fts(wiki_documents_fts, rowid, id, title, content)
                    VALUES ('delete', old.rowid, old.id, old.title, old.content);
                    INSERT INTO wiki_documents_fts(rowid, id, title, content)
                    VALUES (new.rowid, new.id, new.title, new.content);
                END
            """)
            
            // Test cases triggers
            try db.execute(sql: """
                CREATE TRIGGER test_cases_ai AFTER INSERT ON test_cases BEGIN
                    INSERT INTO test_cases_fts(rowid, id, title, content)
                    VALUES (new.rowid, new.id, new.title, new.description);
                END
            """)
            try db.execute(sql: """
                CREATE TRIGGER test_cases_ad AFTER DELETE ON test_cases BEGIN
                    INSERT INTO test_cases_fts(test_cases_fts, rowid, id, title, content)
                    VALUES ('delete', old.rowid, old.id, old.title, old.description);
                END
            """)
            try db.execute(sql: """
                CREATE TRIGGER test_cases_au AFTER UPDATE ON test_cases BEGIN
                    INSERT INTO test_cases_fts(test_cases_fts, rowid, id, title, content)
                    VALUES ('delete', old.rowid, old.id, old.title, old.description);
                    INSERT INTO test_cases_fts(rowid, id, title, content)
                    VALUES (new.rowid, new.id, new.title, new.description);
                END
            """)
        }
        
        try migrator.migrate(self.dbQueue)
    }
}
