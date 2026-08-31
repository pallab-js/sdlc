import Foundation

@MainActor
public class WikiViewModel: ObservableObject {
    private let env: AppEnvironment
    
    @Published public var documents: [WikiDocument] = []
    @Published public var selectedDoc: WikiDocument?
    @Published public var isEditing = false
    @Published public var titleInput = ""
    @Published public var contentInput = ""
    @Published public var showError = false
    @Published public var errorMessage = ""
    
    public init(env: AppEnvironment) {
        self.env = env
    }
    
    public func loadDocuments() {
        guard let ws = env.activeWorkspace else {
            documents = []
            selectedDoc = nil
            return
        }
        Task {
            do {
                documents = try await env.wikiRepository.fetchAll(forWorkspace: ws.id)
                if selectedDoc == nil {
                    selectedDoc = documents.first
                }
            } catch {
                env.logger.error("Failed to load wiki: \(error)")
            }
        }
    }
    
    public func createDocument() {
        guard let ws = env.activeWorkspace else { return }
        let trimmedTitle = titleInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, trimmedTitle.count <= 200 else { return }
        guard contentInput.count <= 5000 else { return }
        let newDoc = WikiDocument(workspaceId: ws.id, title: trimmedTitle, content: contentInput)
        Task {
            do {
                try await env.wikiRepository.insert(newDoc)
                try await env.auditLogService.log(workspaceId: ws.id, action: "CREATE", entityType: "WikiDocument", entityId: newDoc.id, details: "Created wiki page: \(newDoc.title)")
                loadDocuments()
                selectedDoc = documents.first(where: { $0.id == newDoc.id })
            } catch {
                env.logger.error("Failed to create wiki doc: \(error)")
            }
        }
    }
    
    public func saveDocument(_ doc: WikiDocument) {
        var updated = doc
        updated.title = titleInput
        updated.content = contentInput
        guard let ws = env.activeWorkspace else { return }
        Task {
            do {
                try await env.wikiRepository.update(updated)
                try await env.auditLogService.log(workspaceId: ws.id, action: "UPDATE", entityType: "WikiDocument", entityId: updated.id, details: "Updated wiki page: \(updated.title)")
                isEditing = false
                loadDocuments()
                selectedDoc = documents.first(where: { $0.id == updated.id })
            } catch {
                env.logger.error("Failed to save wiki doc: \(error)")
            }
        }
    }
    
    public func deleteDocument(_ doc: WikiDocument) {
        guard let ws = env.activeWorkspace else { return }
        Task {
            do {
                try await env.wikiRepository.delete(doc)
                try await env.auditLogService.log(workspaceId: ws.id, action: "DELETE", entityType: "WikiDocument", entityId: doc.id, details: "Deleted wiki page: \(doc.title)")
                selectedDoc = nil
                loadDocuments()
            } catch {
                env.logger.error("Failed to delete wiki doc: \(error)")
            }
        }
    }
    
    public func startEditing(_ doc: WikiDocument) {
        titleInput = doc.title
        contentInput = doc.content
        isEditing = true
    }
    
    public func cancelEditing() {
        isEditing = false
        titleInput = ""
        contentInput = ""
    }
}
