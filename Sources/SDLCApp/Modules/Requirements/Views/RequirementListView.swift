import SwiftUI

public struct RequirementListView: View {
    @EnvironmentObject var env: AppEnvironment
    @StateObject private var viewModel: RequirementListViewModel
    @State private var isShowingCreateSheet = false
    
    public init(env: AppEnvironment) {
        _viewModel = StateObject(wrappedValue: RequirementListViewModel(env: env))
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Requirements")
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
                        Label("New Requirement", systemImage: "plus")
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
            } else if viewModel.requirements.isEmpty {
                EmptyStateView(
                    systemImageName: "doc.richtext",
                    title: "No Requirements Found",
                    description: "Create your first product requirement to start tracing features.",
                    actionTitle: "New Requirement",
                    action: { isShowingCreateSheet = true }
                )
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.requirements) { req in
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(req.title)
                                    .font(.headline)
                                Text(req.description.isEmpty ? "No description provided." : req.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            Spacer()
                            
                            Text(req.status)
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.indigo.opacity(0.15))
                                .foregroundColor(.indigo)
                                .cornerRadius(6)
                            
                            Button(action: {
                                if let ws = env.activeWorkspace {
                                    Swift.Task {
                                        await viewModel.deleteRequirement(req, workspaceId: ws.id)
                                    }
                                }
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
                Text("Create New Requirement")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Requirement Title")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Enter title", text: $viewModel.titleInput)
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
                
                Picker("Status", selection: $viewModel.statusInput) {
                    ForEach(["DRAFT", "PROPOSED", "APPROVED", "IMPLEMENTED"], id: \.self) { status in
                        Text(status).tag(status)
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
                                await viewModel.createRequirement(workspaceId: ws.id)
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
                    await viewModel.loadRequirements(workspaceId: ws.id)
                }
            }
        }
        .onChange(of: env.activeWorkspace?.id) { _, newId in
            if let id = newId {
                Swift.Task {
                    await viewModel.loadRequirements(workspaceId: id)
                }
            } else {
                viewModel.requirements = []
            }
        }
    }
}
