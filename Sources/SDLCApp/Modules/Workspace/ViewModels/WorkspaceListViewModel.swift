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
        guard !nameInput.isEmpty else {
            errorMessage = "Workspace name cannot be empty."
            showError = true
            return
        }
        guard !pathInput.isEmpty else {
            errorMessage = "Please choose a workspace folder."
            showError = true
            return
        }
        
        await env.createWorkspace(name: nameInput, path: pathInput)
        
        // Reset fields
        nameInput = ""
        pathInput = ""
    }
}
