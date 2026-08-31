import SwiftUI

public struct SearchView: View {
    @EnvironmentObject var env: AppEnvironment
    @StateObject private var viewModel: SearchViewModel

    public init(env: AppEnvironment) {
        _viewModel = StateObject(wrappedValue: SearchViewModel(env: env))
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Search")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    if let ws = env.activeWorkspace {
                        Text("Workspace: \(ws.name)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search projects, tasks, requirements, issues, wiki, test cases...", text: $viewModel.query)
                    .textFieldStyle(.plain)
                    .font(.title3)
                if !viewModel.query.isEmpty {
                    Button(action: { viewModel.clear() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                if viewModel.isSearching {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            if env.activeWorkspace == nil {
                EmptyStateView(systemImageName: "magnifyingglass", title: "No Workspace Active", description: "Select a workspace to search within its contents.")
                    .frame(maxHeight: .infinity)
            } else if viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                EmptyStateView(systemImageName: "magnifyingglass", title: "Search your SDLC workspace", description: "Type to search across projects, tasks, requirements, issues, wiki pages, and test cases.")
                    .frame(maxHeight: .infinity)
            } else if viewModel.results.isEmpty {
                EmptyStateView(systemImageName: "questionmark.circle", title: "No Results Found", description: "Try searching with different terms or check spelling.")
                    .frame(maxHeight: .infinity)
            } else {
                List(viewModel.results) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(item.type.uppercased())
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.indigo.opacity(0.15))
                                .foregroundColor(.indigo)
                                .cornerRadius(6)

                            Text(item.title)
                                .font(.headline)
                        }

                        Text(item.snippet)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .onChange(of: viewModel.query) { _, _ in
            viewModel.search()
        }
    }
}
