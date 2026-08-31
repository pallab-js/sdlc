import Testing
@testable import SDLCApp
import GRDB

struct DatabaseMigrationTests {
    @Test func testMigrationsApplyCleanly() throws {
        let dbService = try DatabaseService(inMemory: true)
        
        
        try dbService.dbQueue.read { db in
            let workspacesExist = try db.tableExists("workspaces")
            let projectsExist = try db.tableExists("projects")
            let requirementsExist = try db.tableExists("requirements")
            let tasksExist = try db.tableExists("tasks")
            let issuesExist = try db.tableExists("issues")
            let wikiExist = try db.tableExists("wiki_documents")
            let testCasesExist = try db.tableExists("test_cases")
            let logsExist = try db.tableExists("activity_logs")
            let attachmentsExist = try db.tableExists("attachments")
            let sprintsExist = try db.tableExists("sprints")
            
            #expect(workspacesExist)
            #expect(projectsExist)
            #expect(requirementsExist)
            #expect(tasksExist)
            #expect(issuesExist)
            #expect(wikiExist)
            #expect(testCasesExist)
            #expect(logsExist)
            #expect(attachmentsExist)
            #expect(sprintsExist)
        }
    }
}
