import Foundation
import Combine

@MainActor
public class TaskListViewModel: ObservableObject {
    private let env: AppEnvironment
    
    @Published public var tasks: [ProjectTask] = []
    @Published public var titleInput: String = ""
    @Published public var descInput: String = ""
    @Published public var statusInput: Status = .todo
    @Published public var priorityInput: Priority = .medium
    @Published public var dueDateInput: Date = Date()
    @Published public var isDueDateEnabled: Bool = false
    @Published public var showError: Bool = false
    @Published public var errorMessage: String = ""
    
    public init(env: AppEnvironment) {
        self.env = env
    }
    
    public func tasks(for status: Status) -> [ProjectTask] {
        tasks.filter { $0.status == status }
    }
    
    public func loadTasks(projectId: UUID) async {
        do {
            self.tasks = try await env.taskRepository.fetchAll(forProject: projectId)
        } catch {
            errorMessage = "Failed to load tasks: \(error.localizedDescription)"
            showError = true
            env.logger.error("Failed to load tasks: \(error)")
        }
    }
    
    public func createTask(projectId: UUID, workspaceId: UUID) async {
        do {
            try InputValidator.validateName(titleInput, fieldName: "Task title")
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
        
        let newTask = ProjectTask(
            projectId: projectId,
            title: titleInput.trimmingCharacters(in: .whitespacesAndNewlines),
            description: descInput,
            status: statusInput,
            priority: priorityInput,
            dueDate: isDueDateEnabled ? dueDateInput : nil
        )
        
        do {
            try await env.taskRepository.insert(newTask)
            try await env.auditLogService.log(
                workspaceId: workspaceId,
                action: "CREATE",
                entityType: "Task",
                entityId: newTask.id,
                details: "Created task \(newTask.title)"
            )
            await loadTasks(projectId: projectId)
            
            titleInput = ""
            descInput = ""
            statusInput = .todo
            priorityInput = .medium
            isDueDateEnabled = false
            showError = false
        } catch {
            errorMessage = "Failed to create task: \(error.localizedDescription)"
            showError = true
            env.logger.error("Failed to create task: \(error)")
        }
    }
    
    public func updateTaskStatus(_ task: ProjectTask, to newStatus: Status, workspaceId: UUID) async {
        var updated = task
        updated.status = newStatus
        do {
            try await env.taskRepository.update(updated)
            try await env.auditLogService.log(
                workspaceId: workspaceId,
                action: "UPDATE",
                entityType: "Task",
                entityId: task.id,
                details: "Updated task \(task.title) status to \(newStatus.rawValue)"
            )
            await loadTasks(projectId: task.projectId)
        } catch {
            errorMessage = "Failed to update task: \(error.localizedDescription)"
            showError = true
            env.logger.error("Failed to update task status: \(error)")
        }
    }
    
    public func deleteTask(_ task: ProjectTask, workspaceId: UUID) async {
        do {
            try await env.taskRepository.delete(task)
            try await env.auditLogService.log(
                workspaceId: workspaceId,
                action: "DELETE",
                entityType: "Task",
                entityId: task.id,
                details: "Soft deleted task \(task.title)"
            )
            await loadTasks(projectId: task.projectId)
        } catch {
            errorMessage = "Failed to delete task: \(error.localizedDescription)"
            showError = true
            env.logger.error("Failed to delete task: \(error)")
        }
    }
}
