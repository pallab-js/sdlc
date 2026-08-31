import SwiftUI

public struct TestingView: View {
    @EnvironmentObject var env: AppEnvironment
    @StateObject private var viewModel: TestingViewModel
    @State private var activeTask: Swift.Task<Void, Never>?
    @State private var testCaseToDelete: TestCase?
    @State private var isShowingDeleteConfirmation = false

    public init(env: AppEnvironment) {
        _viewModel = StateObject(wrappedValue: TestingViewModel(env: env))
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Test Management")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    if let ws = env.activeWorkspace {
                        Text("Workspace: \(ws.name)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                if env.activeWorkspace != nil {
                    Button(action: { viewModel.isShowingCreateSheet = true }) {
                        Label("New Test Case", systemImage: "plus")
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
            } else if viewModel.testCases.isEmpty {
                EmptyStateView(
                    systemImageName: "checklist",
                    title: "No Test Cases",
                    description: "Create your first test case to start tracking quality.",
                    actionTitle: "New Test Case",
                    action: { viewModel.isShowingCreateSheet = true }
                )
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.testCases) { tc in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(tc.title)
                                .font(.headline)

                            Text(tc.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)

                            HStack {
                                Text("Expected: \(tc.expectedResult)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)

                                Spacer()

                                Button(action: {
                                    testCaseToDelete = tc
                                    isShowingDeleteConfirmation = true
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
                .listStyle(.inset)
            }
        }
        .sheet(isPresented: $viewModel.isShowingCreateSheet) {
            VStack(spacing: 20) {
                Text("New Test Case")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Title")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Enter test case title", text: $viewModel.testCaseInput.title)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Description")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $viewModel.testCaseInput.description)
                        .frame(height: 60)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2)))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Expected Result")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $viewModel.testCaseInput.expectedResult)
                        .frame(height: 60)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2)))
                }

                if !viewModel.requirements.isEmpty {
                    Picker("Linked Requirement", selection: $viewModel.testCaseInput.requirementId) {
                        Text("None").tag(nil as UUID?)
                        ForEach(viewModel.requirements) { req in
                            Text(req.title).tag(req.id as UUID?)
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
                    Button("Cancel") { viewModel.isShowingCreateSheet = false }
                        .buttonStyle(.bordered)
                    Button("Create") {
                        if let ws = env.activeWorkspace {
                            activeTask = Swift.Task {
                                await viewModel.createTestCase(workspaceId: ws.id)
                                if !Swift.Task.isCancelled && !viewModel.showError {
                                    viewModel.isShowingCreateSheet = false
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
        .alert("Delete Test Case", isPresented: $isShowingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { testCaseToDelete = nil }
            Button("Delete", role: .destructive) {
                if let tc = testCaseToDelete, let ws = env.activeWorkspace {
                    activeTask = Swift.Task {
                        await viewModel.deleteTestCase(tc, workspaceId: ws.id)
                    }
                }
                testCaseToDelete = nil
            }
        } message: {
            if let tc = testCaseToDelete {
                Text("Are you sure you want to delete \"\(tc.title)\"? This action cannot be undone.")
            }
        }
        .onAppear {
            if let ws = env.activeWorkspace {
                activeTask = Swift.Task {
                    await viewModel.loadTestCases(workspaceId: ws.id)
                    await viewModel.loadRequirements(workspaceId: ws.id)
                }
            }
        }
        .onChange(of: env.activeWorkspace?.id) { _, newId in
            activeTask?.cancel()
            if let id = newId {
                activeTask = Swift.Task {
                    await viewModel.loadTestCases(workspaceId: id)
                    await viewModel.loadRequirements(workspaceId: id)
                }
            } else {
                viewModel.testCases = []
                viewModel.requirements = []
            }
        }
        .onDisappear {
            activeTask?.cancel()
        }
    }
}
