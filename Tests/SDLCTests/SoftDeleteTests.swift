import Testing
@testable import SDLCApp
import GRDB
import Foundation

struct SoftDeleteTests {
    private let dbService: DatabaseService
    private let workspaceRepo: WorkspaceRepository
    private let projectRepo: ProjectRepository
    private let taskRepo: ProjectTaskRepository
    private let issueRepo: IssueRepository
    private let requirementRepo: RequirementRepository
    private let wikiRepo: WikiRepository
    private let testingRepo: TestingRepository
    
    init() throws {
        dbService = try DatabaseService(inMemory: true)
        workspaceRepo = WorkspaceRepository(dbQueue: dbService.dbQueue)
        projectRepo = ProjectRepository(dbQueue: dbService.dbQueue)
        taskRepo = ProjectTaskRepository(dbQueue: dbService.dbQueue)
        issueRepo = IssueRepository(dbQueue: dbService.dbQueue)
        requirementRepo = RequirementRepository(dbQueue: dbService.dbQueue)
        wikiRepo = WikiRepository(dbQueue: dbService.dbQueue)
        testingRepo = TestingRepository(dbQueue: dbService.dbQueue)
    }
    
    @Test func testProjectFetchIdExcludesSoftDeleted() async throws {
        let ws = Workspace(name: "WS", path: "/path")
        try await workspaceRepo.insert(ws)
        
        let project = Project(workspaceId: ws.id, name: "P1", description: "D1")
        try await projectRepo.insert(project)
        
        // Fetch before delete
        let fetched = try await projectRepo.fetch(id: project.id)
        #expect(fetched != nil)
        
        // Soft delete
        try await projectRepo.delete(project)
        
        // fetch(id:) should return nil for soft-deleted
        let afterDelete = try await projectRepo.fetch(id: project.id)
        #expect(afterDelete == nil)
    }
    
    @Test func testTaskFetchIdExcludesSoftDeleted() async throws {
        let ws = Workspace(name: "WS", path: "/path")
        try await workspaceRepo.insert(ws)
        
        let project = Project(workspaceId: ws.id, name: "P1", description: "D1")
        try await projectRepo.insert(project)
        
        let task = ProjectTask(projectId: project.id, title: "T1", description: "D1", status: .todo, priority: .medium)
        try await taskRepo.insert(task)
        
        let fetched = try await taskRepo.fetch(id: task.id)
        #expect(fetched != nil)
        
        try await taskRepo.delete(task)
        
        let afterDelete = try await taskRepo.fetch(id: task.id)
        #expect(afterDelete == nil)
    }
    
    @Test func testIssueFetchIdExcludesSoftDeleted() async throws {
        let ws = Workspace(name: "WS", path: "/path")
        try await workspaceRepo.insert(ws)
        
        let project = Project(workspaceId: ws.id, name: "P1", description: "D1")
        try await projectRepo.insert(project)
        
        let issue = Issue(projectId: project.id, title: "I1", description: "D1", status: .todo, priority: .medium, severity: .medium)
        try await issueRepo.insert(issue)
        
        let fetched = try await issueRepo.fetch(id: issue.id)
        #expect(fetched != nil)
        
        try await issueRepo.delete(issue)
        
        let afterDelete = try await issueRepo.fetch(id: issue.id)
        #expect(afterDelete == nil)
    }
    
    @Test func testRequirementFetchIdExcludesSoftDeleted() async throws {
        let ws = Workspace(name: "WS", path: "/path")
        try await workspaceRepo.insert(ws)
        
        let req = Requirement(workspaceId: ws.id, title: "R1", description: "D1", status: .draft)
        try await requirementRepo.insert(req)
        
        let fetched = try await requirementRepo.fetch(id: req.id)
        #expect(fetched != nil)
        
        try await requirementRepo.delete(req)
        
        let afterDelete = try await requirementRepo.fetch(id: req.id)
        #expect(afterDelete == nil)
    }
    
    @Test func testWikiFetchIdExcludesSoftDeleted() async throws {
        let ws = Workspace(name: "WS", path: "/path")
        try await workspaceRepo.insert(ws)
        
        let doc = WikiDocument(workspaceId: ws.id, title: "D1", content: "Content")
        try await wikiRepo.insert(doc)
        
        let fetched = try await wikiRepo.fetch(id: doc.id)
        #expect(fetched != nil)
        
        try await wikiRepo.delete(doc)
        
        let afterDelete = try await wikiRepo.fetch(id: doc.id)
        #expect(afterDelete == nil)
    }
    
    @Test func testTestCaseFetchIdExcludesSoftDeleted() async throws {
        let ws = Workspace(name: "WS", path: "/path")
        try await workspaceRepo.insert(ws)
        
        let req = Requirement(workspaceId: ws.id, title: "R1", description: "D1")
        try await requirementRepo.insert(req)
        
        let tc = TestCase(requirementId: req.id, title: "TC1", description: "D1", expectedResult: "Pass")
        try await testingRepo.insert(tc)
        
        let fetched = try await testingRepo.fetch(id: tc.id)
        #expect(fetched != nil)
        
        try await testingRepo.delete(tc)
        
        let afterDelete = try await testingRepo.fetch(id: tc.id)
        #expect(afterDelete == nil)
    }
}
