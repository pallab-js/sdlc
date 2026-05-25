import SwiftUI
import MarkdownUI

public struct WikiView: View {
    @EnvironmentObject var env: AppEnvironment
    @State private var documents: [WikiDocument] = []
    @State private var selectedDoc: WikiDocument?
    @State private var isEditing = false
    @State private var titleInput = ""
    @State private var contentInput = ""
    @State private var isShowingCreateSheet = false
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 0) {
            VStack {
                HStack {
                    Text("Wiki Pages")
                        .font(.headline)
                    Spacer()
                    if env.activeWorkspace != nil {
                        Button(action: {
                            titleInput = ""
                            contentInput = ""
                            isShowingCreateSheet = true
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
                .padding()
                
                if env.activeWorkspace == nil {
                    Text("Select a workspace first")
                        .foregroundColor(.secondary)
                        .padding()
                } else if documents.isEmpty {
                    Text("No pages yet")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    List(documents, id: \.id, selection: $selectedDoc) { doc in
                        HStack {
                            Image(systemName: "doc.text")
                            Text(doc.title)
                        }
                        .tag(doc)
                    }
                }
            }
            .frame(minWidth: 200, idealWidth: 240)
            
            Divider()
            
            if let doc = selectedDoc {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        if isEditing {
                            TextField("Title", text: $titleInput)
                                .textFieldStyle(.roundedBorder)
                                .font(.title)
                        } else {
                            Text(doc.title)
                                .font(.title)
                                .bold()
                        }
                        Spacer()
                        Button(isEditing ? "Save" : "Edit") {
                            if isEditing {
                                saveDoc(doc)
                            } else {
                                titleInput = doc.title
                                contentInput = doc.content
                                isEditing = true
                            }
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Delete", role: .destructive) {
                            deleteDoc(doc)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    if isEditing {
                        TextEditor(text: $contentInput)
                            .padding()
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                    } else {
                        ScrollView {
                            Markdown(doc.content)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(.top)
            } else {
                EmptyStateView(systemImageName: "doc.text", title: "Select a Document", description: "Select a wiki document from the list or create a new one.")
            }
        }
        .sheet(isPresented: $isShowingCreateSheet) {
            VStack(spacing: 20) {
                Text("New Wiki Document")
                    .font(.headline)
                
                TextField("Document Title", text: $titleInput)
                    .textFieldStyle(.roundedBorder)
                
                TextEditor(text: $contentInput)
                    .frame(height: 150)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                
                HStack {
                    Spacer()
                    Button("Cancel") { isShowingCreateSheet = false }
                    Button("Create") {
                        createDoc()
                        isShowingCreateSheet = false
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .frame(width: 400)
        }
        .onAppear {
            loadDocs()
        }
        .onChange(of: env.activeWorkspace?.id) { _, _ in
            loadDocs()
        }
    }
    
    private func loadDocs() {
        guard let ws = env.activeWorkspace else {
            documents = []
            selectedDoc = nil
            return
        }
        Swift.Task {
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
    
    private func createDoc() {
        guard let ws = env.activeWorkspace, !titleInput.isEmpty else { return }
        let newDoc = WikiDocument(workspaceId: ws.id, title: titleInput, content: contentInput)
        Swift.Task {
            do {
                try await env.wikiRepository.insert(newDoc)
                try await env.auditLogService.log(workspaceId: ws.id, action: "CREATE", entityType: "WikiDocument", entityId: newDoc.id, details: "Created wiki page: \(newDoc.title)")
                loadDocs()
                selectedDoc = newDoc
            } catch {
                env.logger.error("Failed to create wiki doc: \(error)")
            }
        }
    }
    
    private func saveDoc(_ doc: WikiDocument) {
        var updated = doc
        updated.title = titleInput
        updated.content = contentInput
        guard let ws = env.activeWorkspace else { return }
        Swift.Task {
            do {
                try await env.wikiRepository.update(updated)
                try await env.auditLogService.log(workspaceId: ws.id, action: "UPDATE", entityType: "WikiDocument", entityId: updated.id, details: "Updated wiki page: \(updated.title)")
                isEditing = false
                loadDocs()
                selectedDoc = updated
            } catch {
                env.logger.error("Failed to save wiki doc: \(error)")
            }
        }
    }
    
    private func deleteDoc(_ doc: WikiDocument) {
        guard let ws = env.activeWorkspace else { return }
        Swift.Task {
            do {
                try await env.wikiRepository.delete(doc)
                try await env.auditLogService.log(workspaceId: ws.id, action: "DELETE", entityType: "WikiDocument", entityId: doc.id, details: "Deleted wiki page: \(doc.title)")
                selectedDoc = nil
                loadDocs()
            } catch {
                env.logger.error("Failed to delete wiki doc: \(error)")
            }
        }
    }
}

extension WikiDocument: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    public static func == (lhs: WikiDocument, rhs: WikiDocument) -> Bool {
        lhs.id == rhs.id
    }
}
