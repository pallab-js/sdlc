import Foundation
import Combine

@MainActor
public class ReportViewModel: ObservableObject {
    private let env: AppEnvironment

    @Published public var reportData = ReportData()
    @Published public var isLoading = false
    @Published public var showError = false
    @Published public var errorMessage = ""

    public init(env: AppEnvironment) {
        self.env = env
    }

    public var completionProgress: CGFloat {
        guard reportData.totalTasks > 0 else { return 0.0 }
        return CGFloat(reportData.completedTasksCount) / CGFloat(reportData.totalTasks)
    }

    public func refreshSummary(workspaceId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            reportData = try await env.reportRepository.generateSummary(forWorkspace: workspaceId)
        } catch {
            errorMessage = "Failed to load report summary."
            showError = true
            env.logger.error("Failed to load report summary: \(error)")
        }
    }
}
