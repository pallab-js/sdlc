import SwiftUI

public struct ProjectListView: View {
    @EnvironmentObject var env: AppEnvironment
    @StateObject private var viewModel: ProjectListViewModel
    @State private var isShowingCreateSheet = false
    public var onSelectProject: (Project) -> Void
    
    public init(env: AppEnvironment, onSelectProject: @escaping (Project) -> Void) {
        _viewModel = StateObject(wrappedValue: ProjectListViewModel(env: env))
        self.onSelectProject = onSelectProject
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Projects")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    if let ws = env.activeWorkspace {
                        Text("Workspace: \(ws.name)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                if env.activeWorkspace != nil {
                    Button(action: { isShowingCreateSheet = true }) {
                        Label("New Project", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                }
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            if env.activeWorkspace == nil {
                EmptyStateView(
                    systemImageName: "folder",
                    title: "No Workspace Active",
                    description: "Select or create a workspace from the sidebar first."
                )
                .frame(maxHeight: .infinity)
            } else if viewModel.projects.isEmpty {
                EmptyStateView(
                    systemImageName: "square.grid.3x3.topline.filled",
                    title: "No Projects Found",
                    description: "Get started by creating a project for this workspace.",
                    actionTitle: "New Project",
                    action: { isShowingCreateSheet = true }
                )
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 280))], spacing: 16) {
                        ForEach(viewModel.projects) { project in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(project.name)
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .lineLimit(1)
                                    Spacer()
                                    Button(action: {
                                        if let ws = env.activeWorkspace {
                                            Swift.Task {
                                                await viewModel.deleteProject(project, workspaceId: ws.id)
                                            }
                                        }
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(Color.red)
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                Text(project.description.isEmpty ? "No description provided." : project.description)
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                                    .frame(minHeight: 36, alignment: .topLeading)
                                
                                Divider()
                                
                                HStack {
                                    // Status Badge
                                    Text(project.status.displayName)
                                        .font(.system(size: 10, weight: .semibold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(statusColor(project.status).opacity(0.15))
                                        .foregroundColor(statusColor(project.status))
                                        .cornerRadius(6)
                                    
                                    Spacer()
                                    
                                    // Priority Badge
                                    Text(project.priority.displayName)
                                        .font(.system(size: 10, weight: .semibold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(priorityColor(project.priority).opacity(0.15))
                                        .foregroundColor(priorityColor(project.priority))
                                        .cornerRadius(6)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                                    )
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onSelectProject(project)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $isShowingCreateSheet) {
            VStack(spacing: 20) {
                Text("Create New Project")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Project Name")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Enter project name", text: $viewModel.nameInput)
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
                            Swift.Task {
                                await viewModel.createProject(workspaceId: ws.id)
                                isShowingCreateSheet = false
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
        .onAppear {
            if let ws = env.activeWorkspace {
                Swift.Task {
                    await viewModel.loadProjects(workspaceId: ws.id)
                }
            }
        }
        .onChange(of: env.activeWorkspace?.id) { _, newId in
            if let id = newId {
                Swift.Task {
                    await viewModel.loadProjects(workspaceId: id)
                }
            } else {
                viewModel.projects = []
            }
        }
    }
    
    private func statusColor(_ status: Status) -> Color {
        switch status {
        case .backlog: return .secondary
        case .todo: return .blue
        case .inProgress: return .orange
        case .inReview: return .purple
        case .done: return .green
        }
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
