import Foundation
import Combine

@MainActor
public class ProjectListViewModel: ObservableObject {
    private let env: AppEnvironment
    
    @Published public var projects: [Project] = []
    @Published public var nameInput: String = ""
    @Published public var descInput: String = ""
    @Published public var priorityInput: Priority = .medium
    @Published public var statusInput: Status = .todo
    @Published public var showError: Bool = false
    @Published public var errorMessage: String = ""
    
    public init(env: AppEnvironment) {
        self.env = env
    }
    
    public var filteredProjects: [Project] {
        projects
    }
    
    public func loadProjects(workspaceId: UUID) async {
        do {
            self.projects = try await env.projectRepository.fetchAll(forWorkspace: workspaceId)
        } catch {
            errorMessage = "Failed to load projects: \(error.localizedDescription)"
            showError = true
            env.logger.error("Failed to load projects: \(error)")
        }
    }
    
    public func createProject(workspaceId: UUID) async {
        do {
            try InputValidator.validateName(nameInput, fieldName: "Project name")
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
        
        let newProject = Project(
            workspaceId: workspaceId,
            name: nameInput.trimmingCharacters(in: .whitespacesAndNewlines),
            description: descInput,
            status: statusInput,
            priority: priorityInput
        )
        
        do {
            try await env.projectRepository.insert(newProject)
            try await env.auditLogService.log(
                workspaceId: workspaceId,
                action: "CREATE",
                entityType: "Project",
                entityId: newProject.id,
                details: "Created project \(newProject.name)"
            )
            await loadProjects(workspaceId: workspaceId)
            
            nameInput = ""
            descInput = ""
            priorityInput = .medium
            statusInput = .todo
            showError = false
        } catch {
            errorMessage = "Failed to create project: \(error.localizedDescription)"
            showError = true
            env.logger.error("Failed to create project: \(error)")
        }
    }
    
    public func deleteProject(_ project: Project, workspaceId: UUID) async {
        do {
            try await env.projectRepository.delete(project)
            try await env.auditLogService.log(
                workspaceId: workspaceId,
                action: "DELETE",
                entityType: "Project",
                entityId: project.id,
                details: "Soft deleted project \(project.name)"
            )
            await loadProjects(workspaceId: workspaceId)
        } catch {
            errorMessage = "Failed to delete project: \(error.localizedDescription)"
            showError = true
            env.logger.error("Failed to delete project: \(error)")
        }
    }
}
