import Testing
@testable import SDLCApp
import GRDB
import Foundation

struct ServiceTests {
    private let dbService: DatabaseService
    private let requirementRepo: RequirementRepository
    private let issueRepo: IssueRepository
    private let wikiRepo: WikiRepository
    private let testingRepo: TestingRepository
    private let auditLogService: AuditLogService
    private let searchService: SearchService
    private let reportRepo: ReportRepository
    private let projectRepo: ProjectRepository
    private let taskRepo: ProjectTaskRepository
    private let workspaceRepo: WorkspaceRepository

    init() throws {
        dbService = try DatabaseService(inMemory: true)
        requirementRepo = RequirementRepository(dbQueue: dbService.dbQueue)
        issueRepo = IssueRepository(dbQueue: dbService.dbQueue)
        wikiRepo = WikiRepository(dbQueue: dbService.dbQueue)
        testingRepo = TestingRepository(dbQueue: dbService.dbQueue)
        auditLogService = AuditLogService(dbQueue: dbService.dbQueue)
        searchService = SearchService(dbQueue: dbService.dbQueue)
        reportRepo = ReportRepository(dbQueue: dbService.dbQueue)
        projectRepo = ProjectRepository(dbQueue: dbService.dbQueue)
        taskRepo = ProjectTaskRepository(dbQueue: dbService.dbQueue)
        workspaceRepo = WorkspaceRepository(dbQueue: dbService.dbQueue)
    }

    // MARK: - Requirement Repository

    @Test func testRequirementCRUD() async throws {
        let ws = Workspace(name: "WS", path: "/path")
        try await workspaceRepo.insert(ws)

        let req = Requirement(workspaceId: ws.id, title: "Req A", description: "Desc A", status: .draft)
        try await requirementRepo.insert(req)

        let fetched = try await requirementRepo.fetch(id: req.id)
        #expect(fetched != nil)
        #expect(fetched?.title == "Req A")
        #expect(fetched?.status == .draft)

        let all = try await requirementRepo.fetchAll(forWorkspace: ws.id)
        #expect(all.count == 1)

        var updated = req
        updated.title = "Req A Updated"
        updated.status = .approved
        try await requirementRepo.update(updated)
        let fetchedUpdated = try await requirementRepo.fetch(id: req.id)
        #expect(fetchedUpdated?.title == "Req A Updated")
        #expect(fetchedUpdated?.status == .approved)

        try await requirementRepo.delete(req)
        let afterDelete = try await requirementRepo.fetchAll(forWorkspace: ws.id)
        #expect(afterDelete.isEmpty)
    }

    // MARK: - Issue Repository

    @Test func testIssueCRUD() async throws {
        let ws = Workspace(name: "WS", path: "/path")
        try await workspaceRepo.insert(ws)

        let project = Project(workspaceId: ws.id, name: "P1", description: "D1")
        try await projectRepo.insert(project)

        let issue = Issue(projectId: project.id, title: "Bug A", description: "Desc", status: .todo, priority: .high, severity: .critical)
        try await issueRepo.insert(issue)

        let fetched = try await issueRepo.fetch(id: issue.id)
        #expect(fetched != nil)
        #expect(fetched?.title == "Bug A")
        #expect(fetched?.severity == .critical)

        let all = try await issueRepo.fetchAll(forProject: project.id)
        #expect(all.count == 1)

        var updated = issue
        updated.status = .inProgress
        try await issueRepo.update(updated)
        let fetchedUpdated = try await issueRepo.fetch(id: issue.id)
        #expect(fetchedUpdated?.status == .inProgress)

        try await issueRepo.delete(issue)
        let afterDelete = try await issueRepo.fetchAll(forProject: project.id)
        #expect(afterDelete.isEmpty)
    }

    // MARK: - Wiki Repository

    @Test func testWikiCRUD() async throws {
        let ws = Workspace(name: "WS", path: "/path")
        try await workspaceRepo.insert(ws)

        let doc = WikiDocument(workspaceId: ws.id, title: "Doc A", content: "# Hello")
        try await wikiRepo.insert(doc)

        let fetched = try await wikiRepo.fetch(id: doc.id)
        #expect(fetched != nil)
        #expect(fetched?.title == "Doc A")
        #expect(fetched?.content == "# Hello")

        let all = try await wikiRepo.fetchAll(forWorkspace: ws.id)
        #expect(all.count == 1)

        var updated = doc
        updated.title = "Doc A Updated"
        updated.content = "# Updated"
        try await wikiRepo.update(updated)
        let fetchedUpdated = try await wikiRepo.fetch(id: doc.id)
        #expect(fetchedUpdated?.title == "Doc A Updated")
        #expect(fetchedUpdated?.content == "# Updated")

        try await wikiRepo.delete(doc)
        let afterDelete = try await wikiRepo.fetchAll(forWorkspace: ws.id)
        #expect(afterDelete.isEmpty)
    }

    // MARK: - Testing Repository

    @Test func testTestingRepositoryCRUD() async throws {
        let ws = Workspace(name: "WS", path: "/path")
        try await workspaceRepo.insert(ws)

        let req = Requirement(workspaceId: ws.id, title: "Req", description: "Desc")
        try await requirementRepo.insert(req)

        let tc = TestCase(requirementId: req.id, title: "TC A", description: "Desc A", expectedResult: "Pass")
        try await testingRepo.insert(tc)

        let fetched = try await testingRepo.fetch(id: tc.id)
        #expect(fetched != nil)
        #expect(fetched?.title == "TC A")

        let allForReq = try await testingRepo.fetchAll(forRequirement: req.id)
        #expect(allForReq.count == 1)

        let allForWS = try await testingRepo.fetchAll(forWorkspace: ws.id)
        #expect(allForWS.count == 1)

        var updated = tc
        updated.title = "TC A Updated"
        try await testingRepo.update(updated)
        let fetchedUpdated = try await testingRepo.fetch(id: tc.id)
        #expect(fetchedUpdated?.title == "TC A Updated")

        try await testingRepo.delete(tc)
        let afterDelete = try await testingRepo.fetchAll(forWorkspace: ws.id)
        #expect(afterDelete.isEmpty)
    }

    @Test func testTestingRepositoryWorkspaceScoping() async throws {
        let ws1 = Workspace(name: "WS1", path: "/p1")
        let ws2 = Workspace(name: "WS2", path: "/p2")
        try await workspaceRepo.insert(ws1)
        try await workspaceRepo.insert(ws2)

        let req1 = Requirement(workspaceId: ws1.id, title: "R1", description: "")
        let req2 = Requirement(workspaceId: ws2.id, title: "R2", description: "")
        try await requirementRepo.insert(req1)
        try await requirementRepo.insert(req2)

        let tc1 = TestCase(requirementId: req1.id, title: "TC1", description: "", expectedResult: "P")
        let tc2 = TestCase(requirementId: req2.id, title: "TC2", description: "", expectedResult: "P")
        try await testingRepo.insert(tc1)
        try await testingRepo.insert(tc2)

        let ws1Cases = try await testingRepo.fetchAll(forWorkspace: ws1.id)
        let ws2Cases = try await testingRepo.fetchAll(forWorkspace: ws2.id)
        #expect(ws1Cases.count == 1)
        #expect(ws2Cases.count == 1)
        #expect(ws1Cases.first?.title == "TC1")
        #expect(ws2Cases.first?.title == "TC2")
    }

    // MARK: - Search Service

    @Test func testSearchServiceFindsByName() async throws {
        let ws = Workspace(name: "WS", path: "/path")
        try await workspaceRepo.insert(ws)

        let project = Project(workspaceId: ws.id, name: "MyApp Backend", description: "Server code")
        try await projectRepo.insert(project)

        let results = try await searchService.search(query: "MyApp", workspaceId: ws.id)
        #expect(!results.isEmpty)
        #expect(results.contains(where: { $0.type == "Project" && $0.title == "MyApp Backend" }))
    }

    @Test func testSearchServiceFindsByDescription() async throws {
        let ws = Workspace(name: "WS", path: "/path")
        try await workspaceRepo.insert(ws)

        let project = Project(workspaceId: ws.id, name: "P1", description: "This is an important server component")
        try await projectRepo.insert(project)

        let results = try await searchService.search(query: "important", workspaceId: ws.id)
        #expect(!results.isEmpty)
    }

    @Test func testSearchServiceReturnsEmptyForNoMatch() async throws {
        let ws = Workspace(name: "WS", path: "/path")
        try await workspaceRepo.insert(ws)

        let results = try await searchService.search(query: "zzz_nonexistent_zzz", workspaceId: ws.id)
        #expect(results.isEmpty)
    }

    @Test func testSearchServiceReturnsEmptyForEmptyQuery() async throws {
        let ws = Workspace(name: "WS", path: "/path")
        let results = try await searchService.search(query: "", workspaceId: ws.id)
        #expect(results.isEmpty)
    }

    @Test func testSearchServiceSearchesAllEntityTypes() async throws {
        let ws = Workspace(name: "WS", path: "/path")
        try await workspaceRepo.insert(ws)

        let project = Project(workspaceId: ws.id, name: "Project X", description: "A")
        try await projectRepo.insert(project)
        let task = ProjectTask(projectId: project.id, title: "Task X", description: "B", status: .todo, priority: .medium)
        try await taskRepo.insert(task)
        let req = Requirement(workspaceId: ws.id, title: "Req X", description: "C")
        try await requirementRepo.insert(req)
        let issue = Issue(projectId: project.id, title: "Issue X", description: "D", status: .todo, priority: .medium, severity: .medium)
        try await issueRepo.insert(issue)
        let doc = WikiDocument(workspaceId: ws.id, title: "Wiki X", content: "E")
        try await wikiRepo.insert(doc)
        let tc = TestCase(requirementId: req.id, title: "TC X", description: "F", expectedResult: "G")
        try await testingRepo.insert(tc)

        let results = try await searchService.search(query: "X", workspaceId: ws.id)
        let types = Set(results.map { $0.type })
        #expect(types.contains("Project"))
        #expect(types.contains("Task"))
        #expect(types.contains("Requirement"))
        #expect(types.contains("Issue"))
        #expect(types.contains("Wiki"))
        #expect(types.contains("Test Case"))
    }

    // MARK: - Audit Log Service

    @Test func testAuditLogService() async throws {
        let ws = Workspace(name: "WS", path: "/path")
        try await workspaceRepo.insert(ws)

        try await auditLogService.log(workspaceId: ws.id, action: "CREATE", entityType: "TestEntity", entityId: UUID(), details: "Created test entity")

        let logs = try await auditLogService.fetchLogs(forWorkspace: ws.id)
        #expect(logs.count == 1)
        #expect(logs.first?.action == "CREATE")
        #expect(logs.first?.entityType == "TestEntity")
        #expect(logs.first?.details == "Created test entity")
    }

    @Test func testAuditLogServiceWorkspaceIsolation() async throws {
        let ws1 = Workspace(name: "WS1", path: "/p1")
        let ws2 = Workspace(name: "WS2", path: "/p2")
        try await workspaceRepo.insert(ws1)
        try await workspaceRepo.insert(ws2)

        try await auditLogService.log(workspaceId: ws1.id, action: "CREATE", entityType: "E1", entityId: UUID(), details: "In WS1")
        try await auditLogService.log(workspaceId: ws2.id, action: "UPDATE", entityType: "E2", entityId: UUID(), details: "In WS2")

        let logs1 = try await auditLogService.fetchLogs(forWorkspace: ws1.id)
        let logs2 = try await auditLogService.fetchLogs(forWorkspace: ws2.id)
        #expect(logs1.count == 1)
        #expect(logs2.count == 1)
        #expect(logs1.first?.details == "In WS1")
        #expect(logs2.first?.details == "In WS2")
    }

    @Test func testAuditLogServiceOrdersByNewestFirst() async throws {
        let ws = Workspace(name: "WS", path: "/path")
        try await workspaceRepo.insert(ws)

        try await auditLogService.log(workspaceId: ws.id, action: "FIRST", entityType: "E", entityId: UUID(), details: "First")
        try await Swift.Task.sleep(nanoseconds: 1_000_000)
        try await auditLogService.log(workspaceId: ws.id, action: "SECOND", entityType: "E", entityId: UUID(), details: "Second")

        let logs = try await auditLogService.fetchLogs(forWorkspace: ws.id)
        #expect(logs.count == 2)
        #expect(logs.first?.action == "SECOND")
        #expect(logs.last?.action == "FIRST")
    }

    // MARK: - Report Repository

    @Test func testReportRepositoryEmptyWorkspace() async throws {
        let ws = Workspace(name: "WS", path: "/path")
        try await workspaceRepo.insert(ws)

        let report = try await reportRepo.generateSummary(forWorkspace: ws.id)
        #expect(report.totalProjects == 0)
        #expect(report.totalTasks == 0)
        #expect(report.completedTasksCount == 0)
        #expect(report.activeIssuesCount == 0)
    }

    @Test func testReportRepositoryWithData() async throws {
        let ws = Workspace(name: "WS", path: "/path")
        try await workspaceRepo.insert(ws)

        let project = Project(workspaceId: ws.id, name: "P1", description: "D1")
        try await projectRepo.insert(project)
        let project2 = Project(workspaceId: ws.id, name: "P2", description: "D2")
        try await projectRepo.insert(project2)

        let task1 = ProjectTask(projectId: project.id, title: "T1", description: "", status: .done, priority: .medium)
        let task2 = ProjectTask(projectId: project.id, title: "T2", description: "", status: .todo, priority: .medium)
        let task3 = ProjectTask(projectId: project2.id, title: "T3", description: "", status: .done, priority: .medium)
        try await taskRepo.insert(task1)
        try await taskRepo.insert(task2)
        try await taskRepo.insert(task3)

        let issue = Issue(projectId: project.id, title: "I1", description: "", status: .todo, priority: .medium, severity: .medium)
        try await issueRepo.insert(issue)

        let report = try await reportRepo.generateSummary(forWorkspace: ws.id)
        #expect(report.totalProjects == 2)
        #expect(report.totalTasks == 3)
        #expect(report.completedTasksCount == 2)
        #expect(report.activeIssuesCount == 1)
    }

    @Test func testReportRepositoryRespectsSoftDelete() async throws {
        let ws = Workspace(name: "WS", path: "/path")
        try await workspaceRepo.insert(ws)

        let project = Project(workspaceId: ws.id, name: "P1", description: "D1")
        try await projectRepo.insert(project)

        let task = ProjectTask(projectId: project.id, title: "T1", description: "", status: .done, priority: .medium)
        try await taskRepo.insert(task)
        try await taskRepo.delete(task)

        let report = try await reportRepo.generateSummary(forWorkspace: ws.id)
        #expect(report.totalTasks == 0)
    }
}
