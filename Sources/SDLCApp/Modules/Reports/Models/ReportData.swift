import Foundation

public struct ReportData: Codable, Sendable {
    public var totalProjects: Int
    public var totalTasks: Int
    public var completedTasksCount: Int
    public var activeIssuesCount: Int
    
    public init(totalProjects: Int = 0, totalTasks: Int = 0, completedTasksCount: Int = 0, activeIssuesCount: Int = 0) {
        self.totalProjects = totalProjects
        self.totalTasks = totalTasks
        self.completedTasksCount = completedTasksCount
        self.activeIssuesCount = activeIssuesCount
    }
}
