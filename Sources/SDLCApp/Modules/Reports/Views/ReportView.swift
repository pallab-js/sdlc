import SwiftUI

public struct ReportView: View {
    @EnvironmentObject var env: AppEnvironment
    @StateObject private var viewModel: ReportViewModel
    @State private var task: Swift.Task<Void, Never>?

    public init(env: AppEnvironment) {
        _viewModel = StateObject(wrappedValue: ReportViewModel(env: env))
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Workspace Reports & Insights")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    if let ws = env.activeWorkspace {
                        Text("Workspace: \(ws.name)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Button(action: refreshSummary) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            if env.activeWorkspace == nil {
                EmptyStateView(
                    systemImageName: "chart.bar",
                    title: "No Workspace Active",
                    description: "Select a workspace from the sidebar to view metrics dashboard."
                )
                .frame(maxHeight: .infinity)
            } else if viewModel.isLoading {
                LoadingView(message: "Generating workspace report metrics...")
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        HStack(spacing: 16) {
                            metricCard(
                                title: "Total Projects",
                                value: "\(viewModel.reportData.totalProjects)",
                                icon: "folder.fill",
                                gradientColors: [.blue, .cyan]
                            )
                            metricCard(
                                title: "Total Tasks",
                                value: "\(viewModel.reportData.totalTasks)",
                                icon: "checklist",
                                gradientColors: [.indigo, .purple]
                            )
                            metricCard(
                                title: "Active Issues",
                                value: "\(viewModel.reportData.activeIssuesCount)",
                                icon: "ladybug.fill",
                                gradientColors: [.red, .orange]
                            )
                        }

                        VStack(alignment: .leading, spacing: 16) {
                            Text("Overall Task Progress")
                                .font(.headline)

                            HStack(spacing: 24) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.secondary.opacity(0.15), lineWidth: 12)
                                        .frame(width: 100, height: 100)

                                    Circle()
                                        .trim(from: 0, to: viewModel.completionProgress)
                                        .stroke(
                                            LinearGradient(
                                                colors: [.indigo, .purple],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            ),
                                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                                        )
                                        .frame(width: 100, height: 100)
                                        .rotationEffect(.degrees(-90))

                                    Text("\(Int(viewModel.completionProgress * 100))%")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Completed Tasks: \(viewModel.reportData.completedTasksCount)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text("Pending Tasks: \(max(0, viewModel.reportData.totalTasks - viewModel.reportData.completedTasksCount))")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)

                                    Text("Work completion status based on done state of all tasks logged in this workspace.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineSpacing(3)
                                }
                                Spacer()
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.3))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                                )
                        )

                        Spacer()
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            refreshSummary()
        }
        .onChange(of: env.activeWorkspace?.id) { _, _ -> Void in
            task?.cancel()
            refreshSummary()
        }
        .onDisappear {
            task?.cancel()
        }
    }

    private func refreshSummary() {
        guard let ws = env.activeWorkspace else { return }
        task?.cancel()
        task = Swift.Task {
            await viewModel.refreshSummary(workspaceId: ws.id)
        }
    }

    private func metricCard(title: String, value: String, icon: String, gradientColors: [Color]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(gradientColors.first)
                Spacer()
            }

            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                )
        )
    }
}
