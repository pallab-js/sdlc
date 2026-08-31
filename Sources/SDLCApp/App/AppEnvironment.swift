import Foundation
import GRDB
import Logging

@MainActor
public class AppEnvironment: ObservableObject {
    public let databaseService: DatabaseService
    public let logger: Logger
    
    public let auditLogService: AuditLogService
    public let gitService: GitService
    public let searchService: SearchService
    public let seedDataService: SeedDataService
    public let exportService: WorkspaceExportService
    
    public let workspaceRepository: WorkspaceRepository
    public let projectRepository: ProjectRepository
    public let taskRepository: ProjectTaskRepository
    public let requirementRepository: RequirementRepository
    public let issueRepository: IssueRepository
    public let wikiRepository: WikiRepository
    public let gitRepository: GitRepository
    public let searchRepository: SearchRepository
    public let reportRepository: ReportRepository
    public let testingRepository: TestingRepository
    
    @Published public var activeWorkspace: Workspace?
    @Published public var workspaces: [Workspace] = []
    @Published public var appError: AppError?
    
    public struct AppError: Identifiable {
        public let id = UUID()
        public let message: String
    }
    
    public init(inMemory: Bool = false, dbPath: String? = nil) throws {
        var log = Logger(label: "com.offline.sdlc")
        #if DEBUG
        log.logLevel = .debug
        #else
        log.logLevel = .info
        #endif
        self.logger = log
        
        self.databaseService = try DatabaseService(inMemory: inMemory, dbPath: dbPath)
        
        let queue = databaseService.dbQueue
        
        self.auditLogService = AuditLogService(dbQueue: queue)
        self.gitService = GitService()
        self.searchService = SearchService(dbQueue: queue)
        self.seedDataService = SeedDataService(dbQueue: queue, logger: log)
        self.exportService = WorkspaceExportService(dbQueue: queue)
        
        self.workspaceRepository = WorkspaceRepository(dbQueue: queue)
        self.projectRepository = ProjectRepository(dbQueue: queue)
        self.taskRepository = ProjectTaskRepository(dbQueue: queue)
        self.requirementRepository = RequirementRepository(dbQueue: queue)
        self.issueRepository = IssueRepository(dbQueue: queue)
        self.wikiRepository = WikiRepository(dbQueue: queue)
        self.gitRepository = GitRepository(gitService: gitService)
        self.searchRepository = SearchRepository(searchService: searchService)
        self.reportRepository = ReportRepository(dbQueue: queue)
        self.testingRepository = TestingRepository(dbQueue: queue)
    }
    
    public func showError(_ message: String) {
        appError = AppError(message: message)
    }
    
    @MainActor
    public func loadWorkspaces() async {
        do {
            self.workspaces = try await workspaceRepository.fetchAll()
            if activeWorkspace == nil, let first = workspaces.first {
                activeWorkspace = first
            }
        } catch {
            let msg = "Failed to load workspaces: \(error.localizedDescription)"
            logger.error("\(msg)")
            showError(msg)
        }
    }
    
    @MainActor
    public func selectWorkspace(_ workspace: Workspace) {
        self.activeWorkspace = workspace
    }
    
    @MainActor
    public func createWorkspace(name: String, path: String) async throws {
        try InputValidator.validateName(name, fieldName: "Workspace name")
        try InputValidator.validatePath(path)
        
        let newWorkspace = Workspace(name: name, path: path)
        try await workspaceRepository.insert(newWorkspace)
        try await auditLogService.log(workspaceId: newWorkspace.id, action: "CREATE", entityType: "Workspace", entityId: newWorkspace.id, details: "Created workspace \(name)")
        await loadWorkspaces()
        activeWorkspace = newWorkspace
    }
    
    @MainActor
    public func deleteWorkspace(_ workspace: Workspace) async {
        do {
            try await workspaceRepository.delete(workspace)
            try await auditLogService.log(workspaceId: workspace.id, action: "DELETE", entityType: "Workspace", entityId: workspace.id, details: "Soft deleted workspace \(workspace.name)")
            if activeWorkspace?.id == workspace.id {
                activeWorkspace = nil
            }
            await loadWorkspaces()
        } catch {
            let msg = "Failed to delete workspace: \(error.localizedDescription)"
            logger.error("\(msg)")
            showError(msg)
        }
    }
    
    @MainActor
    public func seedDatabase() async {
        do {
            try await seedDataService.seedAll()
            await loadWorkspaces()
            logger.info("Database seeded successfully")
        } catch {
            let msg = "Failed to seed database: \(error.localizedDescription)"
            logger.error("\(msg)")
            showError(msg)
        }
    }
}
