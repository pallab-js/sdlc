import SwiftUI

public struct TaskListView: View {
    @EnvironmentObject var env: AppEnvironment
    @StateObject private var viewModel: TaskListViewModel
    @State private var isShowingCreateSheet = false
    @State private var activeTask: Task<Void, Never>?
    @State private var taskToDelete: ProjectTask?
    @State private var isShowingDeleteConfirmation = false
    public var project: Project
    public var onBack: () -> Void
    
    public init(env: AppEnvironment, project: Project, onBack: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: TaskListViewModel(env: env))
        self.project = project
        self.onBack = onBack
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) {
                    Label("Back to Projects", systemImage: "chevron.left")
                }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.indigo)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    if let ws = env.activeWorkspace {
                        Text("Workspace: \(ws.name)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: { isShowingCreateSheet = true }) {
                    Label("Add Task", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            if viewModel.tasks.isEmpty {
                EmptyStateView(
                    systemImageName: "checklist",
                    title: "No Tasks Found",
                    description: "Create tasks to organize work for project: \(project.name)",
                    actionTitle: "Add First Task",
                    action: { isShowingCreateSheet = true }
                )
                .frame(maxHeight: .infinity)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 16) {
                        kanbanColumn(title: "Backlog", status: .backlog)
                        kanbanColumn(title: "To Do", status: .todo)
                        kanbanColumn(title: "In Progress", status: .inProgress)
                        kanbanColumn(title: "In Review", status: .inReview)
                        kanbanColumn(title: "Done", status: .done)
                    }
                    .padding()
                }
                .background(Color.gray.opacity(0.05))
            }
        }
        .sheet(isPresented: $isShowingCreateSheet) {
            VStack(spacing: 20) {
                Text("Add New Task")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Task Title")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Enter task title", text: $viewModel.titleInput)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Description")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $viewModel.descInput)
                        .frame(height: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                }
                
                HStack(spacing: 16) {
                Picker("Status", selection: $viewModel.statusInput) {
                    ForEach(Status.allCases) { status in
                        Text(status.displayName).tag(status)
                    }
                }
                    
                    Picker("Priority", selection: $viewModel.priorityInput) {
                        ForEach(Priority.allCases) { priority in
                            Text(priority.displayName).tag(priority)
                        }
                    }
                }
                
                Toggle("Set Due Date", isOn: $viewModel.isDueDateEnabled)
                if viewModel.isDueDateEnabled {
                    DatePicker("Due Date", selection: $viewModel.dueDateInput, displayedComponents: .date)
                }
                
                if viewModel.showError {
                    Text(viewModel.errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                HStack(spacing: 12) {
                    Spacer()
                    Button("Cancel") {
                        isShowingCreateSheet = false
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Create") {
                        if let ws = env.activeWorkspace {
                            activeTask = Task {
                                await viewModel.createTask(projectId: project.id, workspaceId: ws.id)
                                if !Task.isCancelled && !viewModel.showError {
                                    isShowingCreateSheet = false
                                }
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                }
            }
            .padding()
            .frame(width: 450)
        }
        .alert("Delete Task", isPresented: $isShowingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { taskToDelete = nil }
            Button("Delete", role: .destructive) {
                if let t = taskToDelete, let ws = env.activeWorkspace {
                    self.activeTask = Task {
                        await viewModel.deleteTask(t, workspaceId: ws.id)
                    }
                }
                taskToDelete = nil
            }
        } message: {
            if let t = taskToDelete {
                Text("Are you sure you want to delete \"\(t.title)\"? This action cannot be undone.")
            }
        }
        .onAppear {
            activeTask = Task {
                await viewModel.loadTasks(projectId: project.id)
            }
        }
        .onDisappear {
            activeTask?.cancel()
        }
    }
    
    private func kanbanColumn(title: String, status: Status) -> some View {
        let filteredTasks = viewModel.tasks.filter { $0.status == status }
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(filteredTasks.count)")
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.15))
                    .cornerRadius(6)
            }
            .padding(.horizontal, 8)
            
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(filteredTasks) { t in
                        taskCard(task: t)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.3))
        )
    }
    
    private func taskCard(task: ProjectTask) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(task.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                Spacer()
                
                Menu {
                    Button("Move to Backlog") { moveTask(task, to: .backlog) }
                    Button("Move to To Do") { moveTask(task, to: .todo) }
                    Button("Move to In Progress") { moveTask(task, to: .inProgress) }
                    Button("Move to In Review") { moveTask(task, to: .inReview) }
                    Button("Move to Done") { moveTask(task, to: .done) }
                    Divider()
                    Button("Delete", role: .destructive) {
                        taskToDelete = task
                        isShowingDeleteConfirmation = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.secondary)
                }
                .menuStyle(.button)
                .buttonStyle(.plain)
            }
            
            if !task.description.isEmpty {
                Text(task.description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            HStack {
                Text(task.priority.displayName)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(priorityColor(task.priority).opacity(0.15))
                    .foregroundColor(priorityColor(task.priority))
                    .cornerRadius(6)
                
                Spacer()
                
                if let due = task.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                        Text(Self.formatDate(due))
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        )
    }
    
    private func moveTask(_ task: ProjectTask, to status: Status) {
        if let ws = env.activeWorkspace {
            self.activeTask = Task {
                await viewModel.updateTaskStatus(task, to: status, workspaceId: ws.id)
            }
        }
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
    
    private static func formatDate(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }
    
    private func priorityColor(_ priority: Priority) -> Color {
        switch priority {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }
}
