import Foundation
import Combine

@MainActor
public class RequirementListViewModel: ObservableObject {
    private let env: AppEnvironment
    
    @Published public var requirements: [Requirement] = []
    @Published public var titleInput: String = ""
    @Published public var descInput: String = ""
    @Published public var statusInput: RequirementStatus = .draft
    @Published public var showError: Bool = false
    @Published public var errorMessage: String = ""
    
    public init(env: AppEnvironment) {
        self.env = env
    }
    
    public func loadRequirements(workspaceId: UUID) async {
        do {
            self.requirements = try await env.requirementRepository.fetchAll(forWorkspace: workspaceId)
        } catch {
            errorMessage = "Failed to load requirements: \(error.localizedDescription)"
            showError = true
            env.logger.error("Failed to load requirements: \(error)")
        }
    }
    
    public func createRequirement(workspaceId: UUID) async {
        do {
            try InputValidator.validateName(titleInput, fieldName: "Requirement title")
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
        
        let newReq = Requirement(
            workspaceId: workspaceId,
            title: titleInput.trimmingCharacters(in: .whitespacesAndNewlines),
            description: descInput,
            status: statusInput
        )
        
        do {
            try await env.requirementRepository.insert(newReq)
            try await env.auditLogService.log(
                workspaceId: workspaceId,
                action: "CREATE",
                entityType: "Requirement",
                entityId: newReq.id,
                details: "Created requirement: \(newReq.title)"
            )
            await loadRequirements(workspaceId: workspaceId)
            
            titleInput = ""
            descInput = ""
            statusInput = .draft
            showError = false
        } catch {
            errorMessage = "Failed to create requirement: \(error.localizedDescription)"
            showError = true
            env.logger.error("Failed to create requirement: \(error)")
        }
    }
    
    public func deleteRequirement(_ requirement: Requirement, workspaceId: UUID) async {
        do {
            try await env.requirementRepository.delete(requirement)
            try await env.auditLogService.log(
                workspaceId: workspaceId,
                action: "DELETE",
                entityType: "Requirement",
                entityId: requirement.id,
                details: "Soft deleted requirement: \(requirement.title)"
            )
            await loadRequirements(workspaceId: workspaceId)
        } catch {
            errorMessage = "Failed to delete requirement: \(error.localizedDescription)"
            showError = true
            env.logger.error("Failed to delete requirement: \(error)")
        }
    }
}
