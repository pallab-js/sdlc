import Foundation
import GRDB

public struct WorkspaceExportData: Codable, Sendable {
    public let workspace: Workspace
    public let projects: [Project]
    public let requirements: [Requirement]
    public let tasks: [ProjectTask]
    public let issues: [Issue]
    public let wikiDocuments: [WikiDocument]
    public let testCases: [TestCase]
    public let exportedAt: Date
    
    public init(workspace: Workspace, projects: [Project], requirements: [Requirement], tasks: [ProjectTask], issues: [Issue], wikiDocuments: [WikiDocument], testCases: [TestCase], exportedAt: Date = Date()) {
        self.workspace = workspace
        self.projects = projects
        self.requirements = requirements
        self.tasks = tasks
        self.issues = issues
        self.wikiDocuments = wikiDocuments
        self.testCases = testCases
        self.exportedAt = exportedAt
    }
}

public enum ExportImportError: Error, LocalizedError {
    case encodingFailed(Error)
    case decodingFailed(Error)
    case fileWriteFailed(Error)
    case fileReadFailed(Error)
    case invalidData
    
    public var errorDescription: String? {
        switch self {
        case .encodingFailed(let error): return "Failed to encode data: \(error.localizedDescription)"
        case .decodingFailed(let error): return "Failed to decode data: \(error.localizedDescription)"
        case .fileWriteFailed(let error): return "Failed to write file: \(error.localizedDescription)"
        case .fileReadFailed(let error): return "Failed to read file: \(error.localizedDescription)"
        case .invalidData: return "Invalid export data format"
        }
    }
}

public final class WorkspaceExportService: Sendable {
    private let dbQueue: DatabaseQueue
    
    public init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }
    
    public func exportWorkspace(_ workspace: Workspace) async throws -> WorkspaceExportData {
        try await dbQueue.read { db in
            let projects = try Project
                .filter(Column("workspaceId") == workspace.id)
                .filter(Column("deletedAt") == nil)
                .fetchAll(db)
            
            let requirements = try Requirement
                .filter(Column("workspaceId") == workspace.id)
                .filter(Column("deletedAt") == nil)
                .fetchAll(db)
            
            let projectIds = projects.map { $0.id }
            var tasks: [ProjectTask] = []
            for projectId in projectIds {
                let projectTasks = try ProjectTask
                    .filter(Column("projectId") == projectId)
                    .filter(Column("deletedAt") == nil)
                    .fetchAll(db)
                tasks.append(contentsOf: projectTasks)
            }
            
            var issues: [Issue] = []
            for projectId in projectIds {
                let projectIssues = try Issue
                    .filter(Column("projectId") == projectId)
                    .filter(Column("deletedAt") == nil)
                    .fetchAll(db)
                issues.append(contentsOf: projectIssues)
            }
            
            let wikiDocuments = try WikiDocument
                .filter(Column("workspaceId") == workspace.id)
                .filter(Column("deletedAt") == nil)
                .fetchAll(db)
            
            var testCases: [TestCase] = []
            let requirementIds = requirements.map { $0.id }
            for reqId in requirementIds {
                let reqTestCases = try TestCase
                    .filter(Column("requirementId") == reqId)
                    .filter(Column("deletedAt") == nil)
                    .fetchAll(db)
                testCases.append(contentsOf: reqTestCases)
            }
            
            return WorkspaceExportData(
                workspace: workspace,
                projects: projects,
                requirements: requirements,
                tasks: tasks,
                issues: issues,
                wikiDocuments: wikiDocuments,
                testCases: testCases
            )
        }
    }
    
    public func exportWorkspaceToFile(_ workspace: Workspace, to url: URL) async throws {
        let data = try await exportWorkspace(workspace)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            let jsonData = try encoder.encode(data)
            try jsonData.write(to: url, options: .atomic)
        } catch let error as ExportImportError {
            throw error
        } catch {
            throw ExportImportError.fileWriteFailed(error)
        }
    }
    
    public func importWorkspace(from url: URL) async throws -> WorkspaceExportData {
        let jsonData: Data
        do {
            jsonData = try Data(contentsOf: url)
        } catch {
            throw ExportImportError.fileReadFailed(error)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(WorkspaceExportData.self, from: jsonData)
        } catch {
            throw ExportImportError.decodingFailed(error)
        }
    }
    
    public func importWorkspaceData(_ exportData: WorkspaceExportData) async throws {
        let workspace = exportData.workspace
        try await dbQueue.write { db in
            try workspace.insert(db)
            
            for project in exportData.projects {
                try project.insert(db)
            }
            
            for requirement in exportData.requirements {
                try requirement.insert(db)
            }
            
            for task in exportData.tasks {
                try task.insert(db)
            }
            
            for issue in exportData.issues {
                try issue.insert(db)
            }
            
            for doc in exportData.wikiDocuments {
                try doc.insert(db)
            }
            
            for testCase in exportData.testCases {
                try testCase.insert(db)
            }
        }
    }
}
