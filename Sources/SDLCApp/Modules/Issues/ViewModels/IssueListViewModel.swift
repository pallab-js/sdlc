import Foundation
import Combine

@MainActor
public class IssueListViewModel: ObservableObject {
    private let env: AppEnvironment
    
    @Published public var issues: [Issue] = []
    @Published public var titleInput: String = ""
    @Published public var descInput: String = ""
    @Published public var statusInput: Status = .todo
    @Published public var priorityInput: Priority = .medium
    @Published public var severityInput: Severity = .medium
    @Published public var showError: Bool = false
    @Published public var errorMessage: String = ""
    
    public init(env: AppEnvironment) {
        self.env = env
    }
    
    public func loadIssues(projectId: UUID) async {
        do {
            self.issues = try await env.issueRepository.fetchAll(forProject: projectId)
        } catch {
            errorMessage = "Failed to load issues: \(error.localizedDescription)"
            showError = true
            env.logger.error("Failed to load issues: \(error)")
        }
    }
    
    public func createIssue(projectId: UUID, workspaceId: UUID) async {
        do {
            try InputValidator.validateName(titleInput, fieldName: "Issue title")
            try InputValidator.validateDescription(descInput)
        } catch let error as ValidationError {
            errorMessage = error.message
            showError = true
            return
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            return
        }
        
        let newIssue = Issue(
            projectId: projectId,
            title: titleInput.trimmingCharacters(in: .whitespacesAndNewlines),
            description: descInput,
            status: statusInput,
            priority: priorityInput,
            severity: severityInput
        )
        
        do {
            try await env.issueRepository.insert(newIssue)
            try await env.auditLogService.log(
                workspaceId: workspaceId,
                action: "CREATE",
                entityType: "Issue",
                entityId: newIssue.id,
                details: "Created issue: \(newIssue.title)"
            )
            await loadIssues(projectId: projectId)
            
            titleInput = ""
            descInput = ""
            statusInput = .todo
            priorityInput = .medium
            severityInput = .medium
            showError = false
        } catch {
            errorMessage = "Failed to create issue: \(error.localizedDescription)"
            showError = true
            env.logger.error("Failed to create issue: \(error)")
        }
    }
    
    public func deleteIssue(_ issue: Issue, workspaceId: UUID) async {
        do {
            try await env.issueRepository.delete(issue)
            try await env.auditLogService.log(
                workspaceId: workspaceId,
                action: "DELETE",
                entityType: "Issue",
                entityId: issue.id,
                details: "Soft deleted issue: \(issue.title)"
            )
            await loadIssues(projectId: issue.projectId)
        } catch {
            errorMessage = "Failed to delete issue: \(error.localizedDescription)"
            showError = true
            env.logger.error("Failed to delete issue: \(error)")
        }
    }
}
