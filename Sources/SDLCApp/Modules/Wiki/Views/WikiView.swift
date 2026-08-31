import SwiftUI
import MarkdownUI

public struct WikiView: View {
    @EnvironmentObject var env: AppEnvironment
    @StateObject private var viewModel: WikiViewModel
    @State private var isShowingCreateSheet = false
    @State private var isShowingDeleteConfirmation = false
    @State private var docToDelete: WikiDocument?
    
    public init(env: AppEnvironment) {
        _viewModel = StateObject(wrappedValue: WikiViewModel(env: env))
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Wiki")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    if let ws = env.activeWorkspace {
                        Text("Workspace: \(ws.name)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                if env.activeWorkspace != nil {
                    Button(action: {
                        viewModel.titleInput = ""
                        viewModel.contentInput = ""
                        isShowingCreateSheet = true
                    }) {
                        Label("New Page", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                }
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            HStack(spacing: 0) {
                VStack {
                    if env.activeWorkspace == nil {
                        EmptyStateView(
                            systemImageName: "folder",
                            title: "No Workspace Active",
                            description: "Select a workspace from the sidebar first."
                        )
                    } else if viewModel.documents.isEmpty {
                        EmptyStateView(
                            systemImageName: "doc.text",
                            title: "No Pages Yet",
                            description: "Create your first wiki page to start documenting.",
                            actionTitle: "New Page",
                            action: {
                                viewModel.titleInput = ""
                                viewModel.contentInput = ""
                                isShowingCreateSheet = true
                            }
                        )
                    } else {
                        List(viewModel.documents, id: \.id, selection: $viewModel.selectedDoc) { doc in
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
                
                if let doc = viewModel.selectedDoc {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            if viewModel.isEditing {
                                TextField("Title", text: $viewModel.titleInput)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.title)
                            } else {
                                Text(doc.title)
                                    .font(.title)
                                    .bold()
                            }
                            Spacer()
                            Button(viewModel.isEditing ? "Save" : "Edit") {
                                if viewModel.isEditing {
                                    viewModel.saveDocument(doc)
                                } else {
                                    viewModel.startEditing(doc)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.indigo)
                            
                            Button("Delete", role: .destructive) {
                                docToDelete = doc
                                isShowingDeleteConfirmation = true
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.horizontal)
                        
                        Divider()
                        
                        if viewModel.isEditing {
                            TextEditor(text: $viewModel.contentInput)
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
                    EmptyStateView(
                        systemImageName: "doc.text",
                        title: "Select a Document",
                        description: "Select a wiki document from the list or create a new one."
                    )
                }
            }
        }
        .sheet(isPresented: $isShowingCreateSheet) {
            VStack(spacing: 20) {
                Text("New Wiki Document")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Document Title")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Enter title", text: $viewModel.titleInput)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Content")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $viewModel.contentInput)
                        .frame(height: 150)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                }
                
                HStack(spacing: 12) {
                    Spacer()
                    Button("Cancel") {
                        isShowingCreateSheet = false
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Create") {
                        viewModel.createDocument()
                        isShowingCreateSheet = false
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                }
            }
            .padding()
            .frame(width: 450)
        }
        .alert("Delete Wiki Page", isPresented: $isShowingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { docToDelete = nil }
            Button("Delete", role: .destructive) {
                if let doc = docToDelete {
                    viewModel.deleteDocument(doc)
                }
                docToDelete = nil
            }
        } message: {
            if let doc = docToDelete {
                Text("Are you sure you want to delete \"\(doc.title)\"? This action cannot be undone.")
            }
        }
        .onAppear {
            viewModel.loadDocuments()
        }
        .onChange(of: env.activeWorkspace?.id) { _, _ in
            viewModel.loadDocuments()
        }
    }
}
