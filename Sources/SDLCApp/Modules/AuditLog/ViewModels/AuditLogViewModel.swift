import Foundation

@MainActor
public class AuditLogViewModel: ObservableObject {
    private let env: AppEnvironment

    @Published public var logs: [ActivityLog] = []
    @Published public var filterEntityType: String?

    public var filteredLogs: [ActivityLog] {
        if let filter = filterEntityType {
            return logs.filter { $0.entityType == filter }
        }
        return logs
    }

    public var entityTypes: [String] {
        Array(Set(logs.map { $0.entityType })).sorted()
    }

    public init(env: AppEnvironment) {
        self.env = env
    }

    public func loadLogs(workspaceId: UUID) async {
        do {
            logs = try await env.auditLogService.fetchLogs(forWorkspace: workspaceId)
        } catch {
            env.logger.error("Failed to load audit logs: \(error)")
        }
    }

    public func clearFilter() {
        filterEntityType = nil
    }
}
