import Foundation

@MainActor
public class SearchViewModel: ObservableObject {
    private let env: AppEnvironment

    @Published public var query = ""
    @Published public var results = [SearchItem]()
    @Published public var isSearching = false
    @Published public var showError = false
    @Published public var errorMessage = ""

    private var searchTask: Swift.Task<Void, Never>?

    public init(env: AppEnvironment) {
        self.env = env
    }

    public func search() {
        searchTask?.cancel()
        guard let ws = env.activeWorkspace else {
            results = []
            return
        }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = []
            return
        }
        searchTask = Swift.Task {
            isSearching = true
            defer { isSearching = false }
            do {
                try await Swift.Task.sleep(nanoseconds: 150_000_000)
                let items = try await env.searchService.search(query: trimmed, workspaceId: ws.id)
                if !Swift.Task.isCancelled {
                    results = items
                }
            } catch {
                if !Swift.Task.isCancelled {
                    errorMessage = "Search failed: \(error.localizedDescription)"
                    showError = true
                    env.logger.error("Search failed: \(error)")
                }
            }
        }
    }

    public func clear() {
        query = ""
        results = []
        showError = false
        searchTask?.cancel()
    }
}
