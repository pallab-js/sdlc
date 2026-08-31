import SwiftUI
import AppKit

public struct WorkspaceListView: View {
    @EnvironmentObject var env: AppEnvironment
    @StateObject private var viewModel: WorkspaceListViewModel
    @State private var isShowingCreateSheet = false
    @State private var activeTask: Task<Void, Never>?
    @State private var workspaceToDelete: Workspace?
    @State private var isShowingDeleteConfirmation = false
    @State private var exportError: String?
    @State private var importError: String?
    
    public init(env: AppEnvironment) {
        _viewModel = StateObject(wrappedValue: WorkspaceListViewModel(env: env))
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Workspaces")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Spacer()
                
                if env.activeWorkspace != nil {
                    Button(action: exportActiveWorkspace) {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                    .tint(.teal)
                    
                    Button(action: importWorkspace) {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.bordered)
                    .tint(.teal)
                }
                
                Button(action: {
                    activeTask = Task {
                        await env.seedDatabase()
                    }
                }) {
                    Label("Load Sample Data", systemImage: "wand.and.stars")
                }
                .buttonStyle(.bordered)
                .tint(.purple)
                Button(action: { isShowingCreateSheet = true }) {
                    Label("New Workspace", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            if let error = exportError {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Dismiss") { exportError = nil }
                        .buttonStyle(.plain)
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
            }
            
            if let error = importError {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Dismiss") { importError = nil }
                        .buttonStyle(.plain)
                }
                .padding(8)
                .background(Color.red.opacity(0.1))
            }
            
            if env.workspaces.isEmpty {
                EmptyStateView(
                    systemImageName: "folder.badge.plus",
                    title: "No Workspaces Yet",
                    description: "Create or open a workspace to start organizing your software projects offline.",
                    actionTitle: "Create Workspace",
                    action: { isShowingCreateSheet = true }
                )
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(env.workspaces) { workspace in
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(workspace.name)
                                    .font(.headline)
                                Text(workspace.path)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            
                            if env.activeWorkspace?.id == workspace.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                            
                            Button(action: {
                                workspaceToDelete = workspace
                                isShowingDeleteConfirmation = true
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            env.selectWorkspace(workspace)
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .sheet(isPresented: $isShowingCreateSheet) {
            VStack(spacing: 20) {
                Text("Create New Workspace")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Workspace Name")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Enter name", text: $viewModel.nameInput)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Directory Path")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack {
                        TextField("Folder path", text: $viewModel.pathInput)
                            .textFieldStyle(.roundedBorder)
                            .disabled(true)
                        Button("Choose...") {
                            chooseDirectory()
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
                        activeTask = Task {
                            await viewModel.createWorkspace()
                            if !Task.isCancelled && !viewModel.showError {
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
        .alert("Delete Workspace", isPresented: $isShowingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { workspaceToDelete = nil }
            Button("Delete", role: .destructive) {
                if let ws = workspaceToDelete {
                    activeTask = Task {
                        await env.deleteWorkspace(ws)
                    }
                }
                workspaceToDelete = nil
            }
        } message: {
            if let ws = workspaceToDelete {
                Text("Are you sure you want to delete \"\(ws.name)\"? All associated data will be soft-deleted. This action cannot be undone.")
            }
        }
        .onAppear {
            activeTask = Task {
                await env.loadWorkspaces()
            }
        }
        .onDisappear {
            activeTask?.cancel()
        }
    }
    
    private func chooseDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        
        if panel.runModal() == .OK {
            viewModel.pathInput = panel.url?.path ?? ""
            if viewModel.nameInput.isEmpty {
                viewModel.nameInput = panel.url?.lastPathComponent ?? ""
            }
        }
    }
    
    private func exportActiveWorkspace() {
        guard let ws = env.activeWorkspace else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "\(ws.name.replacingOccurrences(of: " ", with: "_"))_export.json"
        panel.title = "Export Workspace"
        
        guard panel.runModal() == .OK, let url = panel.url else { return }
        
        activeTask = Task {
            do {
                try await env.exportService.exportWorkspaceToFile(ws, to: url)
                exportError = nil
            } catch {
                exportError = "Export failed: \(error.localizedDescription)"
                env.logger.error("Export failed: \(error)")
            }
        }
    }
    
    private func importWorkspace() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.title = "Import Workspace"
        
        guard panel.runModal() == .OK, let url = panel.url else { return }
        
        activeTask = Task {
            do {
                let data = try await env.exportService.importWorkspace(from: url)
                try await env.exportService.importWorkspaceData(data)
                importError = nil
                await env.loadWorkspaces()
            } catch {
                importError = "Import failed: \(error.localizedDescription)"
                env.logger.error("Import failed: \(error)")
            }
        }
    }
}
