import SwiftUI
import AppKit

public struct WorkspaceListView: View {
    @EnvironmentObject var env: AppEnvironment
    @StateObject private var viewModel: WorkspaceListViewModel
    @State private var isShowingCreateSheet = false
    
    public init(env: AppEnvironment) {
        _viewModel = StateObject(wrappedValue: WorkspaceListViewModel(env: env))
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Workspaces")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Spacer()
                Button(action: { isShowingCreateSheet = true }) {
                    Label("New Workspace", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
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
                                Swift.Task {
                                    await env.deleteWorkspace(workspace)
                                }
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
                        Swift.Task {
                            await viewModel.createWorkspace()
                            isShowingCreateSheet = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                }
            }
            .padding()
            .frame(width: 400)
        }
        .onAppear {
            Swift.Task {
                await env.loadWorkspaces()
            }
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
}
