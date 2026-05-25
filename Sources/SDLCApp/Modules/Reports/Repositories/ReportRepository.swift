import Foundation
import GRDB

public protocol ReportRepositoryProtocol {
    func generateSummary(forWorkspace workspaceId: UUID) async throws -> ReportData
}

public final class ReportRepository: ReportRepositoryProtocol, Sendable {
    private let dbQueue: DatabaseQueue
    
    public init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }
    
    public func generateSummary(forWorkspace workspaceId: UUID) async throws -> ReportData {
        try await dbQueue.read { db in
            let projectCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM projects WHERE workspaceId = ? AND deletedAt IS NULL", arguments: [workspaceId]) ?? 0
            let taskCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM tasks INNER JOIN projects ON tasks.projectId = projects.id WHERE projects.workspaceId = ? AND tasks.deletedAt IS NULL", arguments: [workspaceId]) ?? 0
            let completedCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM tasks INNER JOIN projects ON tasks.projectId = projects.id WHERE projects.workspaceId = ? AND tasks.status = 'DONE' AND tasks.deletedAt IS NULL", arguments: [workspaceId]) ?? 0
            let activeIssuesCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM issues INNER JOIN projects ON issues.projectId = projects.id WHERE projects.workspaceId = ? AND issues.status != 'DONE' AND issues.deletedAt IS NULL", arguments: [workspaceId]) ?? 0
            
            return ReportData(
                totalProjects: projectCount,
                totalTasks: taskCount,
                completedTasksCount: completedCount,
                activeIssuesCount: activeIssuesCount
            )
        }
    }
}
