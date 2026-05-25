import Foundation
import Combine

@MainActor
public class TaskListViewModel: ObservableObject {
    private let env: AppEnvironment
    
    @Published public var tasks: [Task] = []
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
    
    public func loadTasks(projectId: UUID) async {
        do {
            self.tasks = try await env.taskRepository.fetchAll(forProject: projectId)
        } catch {
            env.logger.error("Failed to load tasks: \(error)")
        }
    }
    
    public func createTask(projectId: UUID, workspaceId: UUID) async {
        guard !titleInput.isEmpty else {
            errorMessage = "Task title cannot be empty."
            showError = true
            return
        }
        
        let newTask = Task(
            projectId: projectId,
            title: titleInput,
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
            
            // reset
            titleInput = ""
            descInput = ""
            statusInput = .todo
            priorityInput = .medium
            isDueDateEnabled = false
        } catch {
            env.logger.error("Failed to create task: \(error)")
        }
    }
    
    public func updateTaskStatus(_ task: Task, to newStatus: Status, workspaceId: UUID) async {
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
            env.logger.error("Failed to update task status: \(error)")
        }
    }
    
    public func deleteTask(_ task: Task, workspaceId: UUID) async {
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
            env.logger.error("Failed to delete task: \(error)")
        }
    }
}
