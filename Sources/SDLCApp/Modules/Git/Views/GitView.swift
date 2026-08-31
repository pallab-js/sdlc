import SwiftUI

public struct GitView: View {
    @EnvironmentObject var env: AppEnvironment
    @State private var commits = [GitCommit]()
    @State private var status = ""
    @State private var activeTask: Swift.Task<Void, Never>?
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Git Browser")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    if let ws = env.activeWorkspace {
                        Text("Workspace: \(ws.name)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Button(action: refreshGitInfo) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            if env.activeWorkspace == nil {
                EmptyStateView(systemImageName: "point.3.connected.trianglepath.dotted", title: "No Workspace Active", description: "Select a workspace to view its Git repository status.")
                    .frame(maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Working Directory Status")
                            .font(.headline)
                        Text(status.isEmpty ? "No status retrieved or folder is not a Git repository." : status)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                            .cornerRadius(8)
                    }
                    .padding([.horizontal, .top])
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Recent Commit History")
                            .font(.headline)
                        
                        if commits.isEmpty {
                            Text("No commits found. Check if the workspace folder contains a Git history.")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            List(commits) { commit in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(commit.message)
                                            .font(.headline)
                                        Spacer()
                                        Text(commit.hash.prefix(7))
                                            .font(.system(.caption, design: .monospaced))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.secondary.opacity(0.15))
                                            .cornerRadius(4)
                                    }
                                    HStack {
                                        Text(commit.author)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("\u{2022}")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(Self.formatDate(commit.date))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)
                    .padding(.horizontal)
                }
            }
        }
        .onAppear {
            refreshGitInfo()
        }
        .onChange(of: env.activeWorkspace?.id) { _, _ in
            activeTask?.cancel()
            refreshGitInfo()
        }
        .onDisappear {
            activeTask?.cancel()
        }
    }
    
    private func refreshGitInfo() {
        guard let ws = env.activeWorkspace else {
            status = ""
            commits = []
            return
        }
        
        activeTask?.cancel()
        activeTask = Swift.Task {
            do {
                status = try await env.gitRepository.getStatus(repoPath: ws.path)
                commits = try await env.gitRepository.getCommits(repoPath: ws.path)
            } catch {
                status = "Error: \(error.localizedDescription)"
                commits = []
            }
        }
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    private static func formatDate(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }
}
