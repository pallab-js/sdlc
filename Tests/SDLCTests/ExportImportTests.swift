import Testing
@testable import SDLCApp
import GRDB
import Foundation

struct ExportImportTests {
    private let dbService: DatabaseService
    private let workspaceRepo: WorkspaceRepository
    private let projectRepo: ProjectRepository
    private let taskRepo: ProjectTaskRepository
    private let requirementRepo: RequirementRepository
    private let issueRepo: IssueRepository
    private let wikiRepo: WikiRepository
    private let testingRepo: TestingRepository
    private let exportService: WorkspaceExportService
    
    init() throws {
        dbService = try DatabaseService(inMemory: true)
        workspaceRepo = WorkspaceRepository(dbQueue: dbService.dbQueue)
        projectRepo = ProjectRepository(dbQueue: dbService.dbQueue)
        taskRepo = ProjectTaskRepository(dbQueue: dbService.dbQueue)
        requirementRepo = RequirementRepository(dbQueue: dbService.dbQueue)
        issueRepo = IssueRepository(dbQueue: dbService.dbQueue)
        wikiRepo = WikiRepository(dbQueue: dbService.dbQueue)
        testingRepo = TestingRepository(dbQueue: dbService.dbQueue)
        exportService = WorkspaceExportService(dbQueue: dbService.dbQueue)
    }
    
    @Test func testExportWorkspaceIncludesAllEntities() async throws {
        let ws = Workspace(name: "Test WS", path: "/test")
        try await workspaceRepo.insert(ws)
        
        let project = Project(workspaceId: ws.id, name: "P1", description: "D1")
        try await projectRepo.insert(project)
        
        let req = Requirement(workspaceId: ws.id, title: "R1", description: "RD1")
        try await requirementRepo.insert(req)
        
        let task = ProjectTask(projectId: project.id, title: "T1", description: "TD1", status: .todo, priority: .medium)
        try await taskRepo.insert(task)
        
        let issue = Issue(projectId: project.id, title: "I1", description: "ID1", status: .todo, priority: .medium, severity: .medium)
        try await issueRepo.insert(issue)
        
        let doc = WikiDocument(workspaceId: ws.id, title: "Doc1", content: "Content")
        try await wikiRepo.insert(doc)
        
        let tc = TestCase(requirementId: req.id, title: "TC1", description: "TCD1", expectedResult: "Pass")
        try await testingRepo.insert(tc)
        
        let exportData = try await exportService.exportWorkspace(ws)
        
        #expect(exportData.workspace.name == "Test WS")
        #expect(exportData.projects.count == 1)
        #expect(exportData.requirements.count == 1)
        #expect(exportData.tasks.count == 1)
        #expect(exportData.issues.count == 1)
        #expect(exportData.wikiDocuments.count == 1)
        #expect(exportData.testCases.count == 1)
    }
    
    @Test func testExportWorkspaceExcludesSoftDeleted() async throws {
        let ws = Workspace(name: "Test WS", path: "/test")
        try await workspaceRepo.insert(ws)
        
        let project = Project(workspaceId: ws.id, name: "P1", description: "D1")
        try await projectRepo.insert(project)
        
        let task = ProjectTask(projectId: project.id, title: "T1", description: "TD1", status: .todo, priority: .medium)
        try await taskRepo.insert(task)
        
        try await taskRepo.delete(task)
        
        let exportData = try await exportService.exportWorkspace(ws)
        #expect(exportData.tasks.isEmpty)
    }
    
    @Test func testExportImportRoundTrip() async throws {
        let ws = Workspace(name: "Export WS", path: "/export")
        try await workspaceRepo.insert(ws)
        
        let project = Project(workspaceId: ws.id, name: "P1", description: "D1")
        try await projectRepo.insert(project)
        
        let exportData = try await exportService.exportWorkspace(ws)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(exportData)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(WorkspaceExportData.self, from: jsonData)
        
        #expect(decoded.workspace.name == "Export WS")
        #expect(decoded.projects.count == 1)
        #expect(decoded.projects.first?.name == "P1")
    }
}
