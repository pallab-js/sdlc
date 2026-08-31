import Foundation
import Combine

@MainActor
public class WorkspaceListViewModel: ObservableObject {
    private let env: AppEnvironment
    
    @Published public var nameInput: String = ""
    @Published public var pathInput: String = ""
    @Published public var showError: Bool = false
    @Published public var errorMessage: String = ""
    
    public init(env: AppEnvironment) {
        self.env = env
    }
    
    public func createWorkspace() async {
        do {
            try await env.createWorkspace(name: nameInput, path: pathInput)
            nameInput = ""
            pathInput = ""
            showError = false
        } catch let error as ValidationError {
            errorMessage = error.message
            showError = true
        } catch {
            errorMessage = "Failed to create workspace: \(error.localizedDescription)"
            showError = true
        }
    }
}
