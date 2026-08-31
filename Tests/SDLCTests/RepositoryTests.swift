import Testing
@testable import SDLCApp
import GRDB
import Foundation

struct RepositoryTests {
    private let dbService: DatabaseService
    private let workspaceRepo: WorkspaceRepository
    private let projectRepo: ProjectRepository
    private let taskRepo: ProjectTaskRepository
    
    init() throws {
        dbService = try DatabaseService(inMemory: true)
        workspaceRepo = WorkspaceRepository(dbQueue: dbService.dbQueue)
        projectRepo = ProjectRepository(dbQueue: dbService.dbQueue)
        taskRepo = ProjectTaskRepository(dbQueue: dbService.dbQueue)
    }
    
    @Test func testWorkspaceCRUD() async throws {
        let ws = Workspace(name: "Test Workspace", path: "/test/path")
        
        // Insert
        try await workspaceRepo.insert(ws)
        
        // Fetch
        let fetched = try await workspaceRepo.fetch(id: ws.id)
        #expect(fetched != nil)
        #expect(fetched?.name == "Test Workspace")
        #expect(fetched?.path == "/test/path")
        
        // Fetch All
        let all = try await workspaceRepo.fetchAll()
        #expect(all.count == 1)
        
        // Update
        var updated = ws
        updated.name = "Updated Workspace"
        try await workspaceRepo.update(updated)
        let fetchedUpdated = try await workspaceRepo.fetch(id: ws.id)
        #expect(fetchedUpdated?.name == "Updated Workspace")
        
        // Soft Delete
        try await workspaceRepo.delete(ws)
        let afterDelete = try await workspaceRepo.fetchAll()
        #expect(afterDelete.isEmpty)
        
        // fetch(id:) should not return soft-deleted workspaces
        let rawFetched = try await workspaceRepo.fetch(id: ws.id)
        #expect(rawFetched == nil)
    }
    
    @Test func testProjectCRUD() async throws {
        let ws = Workspace(name: "WS", path: "/path")
        try await workspaceRepo.insert(ws)
        
        let project = Project(workspaceId: ws.id, name: "Project A", description: "Desc A")
        
        // Insert
        try await projectRepo.insert(project)
        
        // Fetch
        let fetched = try await projectRepo.fetch(id: project.id)
        #expect(fetched != nil)
        #expect(fetched?.name == "Project A")
        #expect(fetched?.workspaceId == ws.id)
        
        // Fetch all for Workspace
        let all = try await projectRepo.fetchAll(forWorkspace: ws.id)
        #expect(all.count == 1)
        
        // Delete
        try await projectRepo.delete(project)
        let allAfterDelete = try await projectRepo.fetchAll(forWorkspace: ws.id)
        #expect(allAfterDelete.isEmpty)
    }
    
    @Test func testTaskCRUD() async throws {
        let ws = Workspace(name: "WS", path: "/path")
        try await workspaceRepo.insert(ws)
        
        let project = Project(workspaceId: ws.id, name: "Project A", description: "Desc A")
        try await projectRepo.insert(project)
        
        let task = ProjectTask(projectId: project.id, title: "Task 1", description: "Desc 1", status: .todo, priority: .high)
        
        // Insert
        try await taskRepo.insert(task)
        
        // Fetch
        let fetched = try await taskRepo.fetch(id: task.id)
        #expect(fetched != nil)
        #expect(fetched?.title == "Task 1")
        #expect(fetched?.status == .todo)
        
        // Fetch all for Project
        let all = try await taskRepo.fetchAll(forProject: project.id)
        #expect(all.count == 1)
        
        // Update Status
        var updated = task
        updated.status = .inProgress
        try await taskRepo.update(updated)
        let fetchedUpdated = try await taskRepo.fetch(id: task.id)
        #expect(fetchedUpdated?.status == .inProgress)
        
        // Delete
        try await taskRepo.delete(task)
        let allAfterDelete = try await taskRepo.fetchAll(forProject: project.id)
        #expect(allAfterDelete.isEmpty)
    }
}
