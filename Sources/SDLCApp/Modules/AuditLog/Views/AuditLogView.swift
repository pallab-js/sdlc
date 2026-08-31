import SwiftUI

public struct AuditLogView: View {
    @EnvironmentObject var env: AppEnvironment
    @StateObject private var viewModel: AuditLogViewModel
    @State private var task: Swift.Task<Void, Never>?

    public init(env: AppEnvironment) {
        _viewModel = StateObject(wrappedValue: AuditLogViewModel(env: env))
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Activity Log")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    if let ws = env.activeWorkspace {
                        Text("Workspace: \(ws.name)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()

                if !viewModel.entityTypes.isEmpty {
                    Picker("Filter", selection: $viewModel.filterEntityType) {
                        Text("All").tag(nil as String?)
                        ForEach(viewModel.entityTypes, id: \.self) { type in
                            Text(type).tag(type as String?)
                        }
                    }
                    .frame(width: 160)
                }
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            if env.activeWorkspace == nil {
                EmptyStateView(
                    systemImageName: "clock.arrow.circlepath",
                    title: "No Workspace Active",
                    description: "Select a workspace to view its activity log."
                )
                .frame(maxHeight: .infinity)
            } else if viewModel.filteredLogs.isEmpty {
                EmptyStateView(
                    systemImageName: "clock.arrow.circlepath",
                    title: "No Activity Yet",
                    description: "Activity from projects, tasks, issues, and other modules will appear here."
                )
                .frame(maxHeight: .infinity)
            } else {
                List(viewModel.filteredLogs) { log in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(colorForAction(log.action))
                            .frame(width: 8, height: 8)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(log.action)
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(colorForAction(log.action).opacity(0.15))
                                    .foregroundColor(colorForAction(log.action))
                                    .cornerRadius(6)

                                Text(log.entityType)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Text(log.details)
                                .font(.subheadline)
                                .lineLimit(2)
                        }

                        Spacer()

                        Text(log.createdAt, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.inset)
            }
        }
        .onAppear {
            if let ws = env.activeWorkspace {
                task = Swift.Task {
                    await viewModel.loadLogs(workspaceId: ws.id)
                }
            }
        }
        .onChange(of: env.activeWorkspace?.id) { _, newId in
            task?.cancel()
            if let id = newId {
                task = Swift.Task {
                    await viewModel.loadLogs(workspaceId: id)
                }
            } else {
                viewModel.logs = []
            }
        }
        .onDisappear {
            task?.cancel()
        }
    }

    private func colorForAction(_ action: String) -> Color {
        switch action {
        case "CREATE": return .green
        case "UPDATE": return .blue
        case "DELETE": return .red
        default: return .secondary
        }
    }
}
