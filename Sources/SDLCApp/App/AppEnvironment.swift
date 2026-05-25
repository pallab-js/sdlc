import Foundation
import GRDB
import Logging

@MainActor
public class AppEnvironment: ObservableObject {
    public let databaseService: DatabaseService
    public let logger: Logger
    
    // Services
    public let auditLogService: AuditLogService
    public let gitService: GitService
    public let searchService: SearchService
    
    // Repositories
    public let workspaceRepository: WorkspaceRepository
    public let projectRepository: ProjectRepository
    public let taskRepository: TaskRepository
    public let requirementRepository: RequirementRepository
    public let issueRepository: IssueRepository
    public let wikiRepository: WikiRepository
    public let gitRepository: GitRepository
    public let searchRepository: SearchRepository
    public let reportRepository: ReportRepository
    public let testingRepository: TestingRepository
    
    // State
    @Published public var activeWorkspace: Workspace?
    @Published public var workspaces: [Workspace] = []
    
    public init(inMemory: Bool = false, dbPath: String? = nil) {
        var log = Logger(label: "com.offline.sdlc")
        log.logLevel = .debug
        self.logger = log
        
        let dbService = DatabaseService(inMemory: inMemory, dbPath: dbPath)
        self.databaseService = dbService
        
        let queue = dbService.dbQueue
        
        self.auditLogService = AuditLogService(dbQueue: queue)
        self.gitService = GitService()
        self.searchService = SearchService(dbQueue: queue)
        
        self.workspaceRepository = WorkspaceRepository(dbQueue: queue)
        self.projectRepository = ProjectRepository(dbQueue: queue)
        self.taskRepository = TaskRepository(dbQueue: queue)
        self.requirementRepository = RequirementRepository(dbQueue: queue)
        self.issueRepository = IssueRepository(dbQueue: queue)
        self.wikiRepository = WikiRepository(dbQueue: queue)
        self.gitRepository = GitRepository(gitService: gitService)
        self.searchRepository = SearchRepository(searchService: searchService)
        self.reportRepository = ReportRepository(dbQueue: queue)
        self.testingRepository = TestingRepository(dbQueue: queue)
    }
    
    @MainActor
    public func loadWorkspaces() async {
        do {
            self.workspaces = try await workspaceRepository.fetchAll()
            if activeWorkspace == nil, let first = workspaces.first {
                activeWorkspace = first
            }
        } catch {
            logger.error("Failed to load workspaces: \(error)")
        }
    }
    
    @MainActor
    public func selectWorkspace(_ workspace: Workspace) {
        self.activeWorkspace = workspace
    }
    
    @MainActor
    public func createWorkspace(name: String, path: String) async {
        let newWorkspace = Workspace(name: name, path: path)
        do {
            try await workspaceRepository.insert(newWorkspace)
            try await auditLogService.log(workspaceId: newWorkspace.id, action: "CREATE", entityType: "Workspace", entityId: newWorkspace.id, details: "Created workspace \(name)")
            await loadWorkspaces()
            activeWorkspace = newWorkspace
        } catch {
            logger.error("Failed to create workspace: \(error)")
        }
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
            logger.error("Failed to delete workspace: \(error)")
        }
    }
}
