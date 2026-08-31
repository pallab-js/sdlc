import SwiftUI

public struct IssueListView: View {
    @EnvironmentObject var env: AppEnvironment
    @StateObject private var viewModel: IssueListViewModel
    @State private var selectedProject: Project?
    @State private var projects: [Project] = []
    @State private var isShowingCreateSheet = false
    @State private var activeTask: Task<Void, Never>?
    @State private var issueToDelete: Issue?
    @State private var isShowingDeleteConfirmation = false
    
    public init(env: AppEnvironment) {
        _viewModel = StateObject(wrappedValue: IssueListViewModel(env: env))
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Issues & Bugs")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    if let ws = env.activeWorkspace {
                        Text("Workspace: \(ws.name)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                
                if !projects.isEmpty {
                    Picker("Project", selection: $selectedProject) {
                        Text("Select Project...").tag(nil as Project?)
                        ForEach(projects) { project in
                            Text(project.name).tag(project as Project?)
                        }
                    }
                    .frame(width: 200)
                }
                
                if selectedProject != nil {
                    Button(action: { isShowingCreateSheet = true }) {
                        Label("New Issue", systemImage: "plus")
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
            } else if projects.isEmpty {
                EmptyStateView(
                    systemImageName: "square.grid.3x3.topline.filled",
                    title: "No Projects Found",
                    description: "You must create a project under this workspace before tracking issues."
                )
                .frame(maxHeight: .infinity)
            } else if selectedProject == nil {
                EmptyStateView(
                    systemImageName: "ladybug",
                    title: "Select a Project",
                    description: "Choose a project from the top menu to view its issue list."
                )
                .frame(maxHeight: .infinity)
            } else if viewModel.issues.isEmpty {
                EmptyStateView(
                    systemImageName: "ladybug.fill",
                    title: "No Issues Logged",
                    description: "Great! No active bugs or issues found for this project.",
                    actionTitle: "Log Issue",
                    action: { isShowingCreateSheet = true }
                )
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.issues) { issue in
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(issue.title)
                                    .font(.headline)
                                Text(issue.description.isEmpty ? "No description." : issue.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            Spacer()
                            
                            Text(issue.severity.displayName)
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(severityColor(issue.severity).opacity(0.15))
                                .foregroundColor(severityColor(issue.severity))
                                .cornerRadius(6)
                            
                            Text(issue.priority.displayName)
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(priorityColor(issue.priority).opacity(0.15))
                                .foregroundColor(priorityColor(issue.priority))
                                .cornerRadius(6)
                            
                            Text(issue.status.displayName)
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(statusColor(issue.status).opacity(0.15))
                                .foregroundColor(statusColor(issue.status))
                                .cornerRadius(6)
                            
                            Button(action: {
                                issueToDelete = issue
                                isShowingDeleteConfirmation = true
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 6)
                    }
                }
                .listStyle(.inset)
            }
        }
        .sheet(isPresented: $isShowingCreateSheet) {
            VStack(spacing: 20) {
                Text("Log New Issue")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Issue Title")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Enter title", text: $viewModel.titleInput)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Description / Repro Steps")
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
                    Picker("Severity", selection: $viewModel.severityInput) {
                        ForEach(Severity.allCases) { severity in
                            Text(severity.displayName).tag(severity)
                        }
                    }
                    
                    Picker("Priority", selection: $viewModel.priorityInput) {
                        ForEach(Priority.allCases) { priority in
                            Text(priority.displayName).tag(priority)
                        }
                    }
                    
                    Picker("Status", selection: $viewModel.statusInput) {
                        ForEach(Status.allCases) { status in
                            Text(status.displayName).tag(status)
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
                    
                    Button("Log Issue") {
                        if let ws = env.activeWorkspace, let project = selectedProject {
                            activeTask = Task {
                                await viewModel.createIssue(projectId: project.id, workspaceId: ws.id)
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
        .alert("Delete Issue", isPresented: $isShowingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { issueToDelete = nil }
            Button("Delete", role: .destructive) {
                if let issue = issueToDelete, let ws = env.activeWorkspace {
                    activeTask = Task {
                        await viewModel.deleteIssue(issue, workspaceId: ws.id)
                    }
                }
                issueToDelete = nil
            }
        } message: {
            if let issue = issueToDelete {
                Text("Are you sure you want to delete \"\(issue.title)\"? This action cannot be undone.")
            }
        }
        .onAppear {
            loadProjectsList()
        }
        .onChange(of: env.activeWorkspace?.id) { _, _ in
            activeTask?.cancel()
            selectedProject = nil
            viewModel.issues = []
            loadProjectsList()
        }
        .onChange(of: selectedProject?.id) { _, newId in
            activeTask?.cancel()
            if let id = newId {
                activeTask = Task {
                    await viewModel.loadIssues(projectId: id)
                }
            } else {
                viewModel.issues = []
            }
        }
        .onDisappear {
            activeTask?.cancel()
        }
    }
    
    private func loadProjectsList() {
        guard let ws = env.activeWorkspace else {
            projects = []
            return
        }
        activeTask = Task {
            do {
                projects = try await env.projectRepository.fetchAll(forWorkspace: ws.id)
                selectedProject = projects.first
            } catch {
                env.logger.error("Failed to load projects list in issues: \(error)")
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
    
    private func severityColor(_ severity: Severity) -> Color {
        switch severity {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .critical: return .red
        case .blocker: return .purple
        }
    }
}
