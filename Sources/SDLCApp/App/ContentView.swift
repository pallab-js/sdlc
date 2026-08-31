import SwiftUI

public struct ContentView: View {
    @EnvironmentObject var env: AppEnvironment
    @State private var selectedModule: SidebarModule = .workspaces
    @State private var selectedProject: Project?
    
    public init() {}
    
    public var body: some View {
        NavigationSplitView {
            List(SidebarModule.allCases, selection: $selectedModule) { module in
                NavigationLink(value: module) {
                    Label(module.rawValue, systemImage: module.iconName)
                }
                .accessibilityLabel(module.rawValue)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 180, ideal: 220)
            
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Divider()
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.indigo)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            if let ws = env.activeWorkspace {
                                Text(ws.name)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .lineLimit(1)
                                Text(ws.path)
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            } else {
                                Text("No Active Workspace")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(Color(nsColor: .windowBackgroundColor))
                }
            }
        } detail: {
            switch selectedModule {
            case .workspaces:
                WorkspaceListView(env: env)
            case .projects:
                if let project = selectedProject {
                    TaskListView(env: env, project: project, onBack: {
                        self.selectedProject = nil
                    })
                } else {
                    ProjectListView(env: env, onSelectProject: { project in
                        self.selectedProject = project
                    })
                }
            case .wiki:
                WikiView(env: env)
            case .git:
                GitView()
            case .search:
                SearchView(env: env)
            case .requirements:
                RequirementListView(env: env)
            case .issues:
                IssueListView(env: env)
            case .reports:
                ReportView(env: env)
            case .testing:
                TestingView(env: env)
            case .auditLog:
                AuditLogView(env: env)
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .onChange(of: env.activeWorkspace?.id) { _, _ in
            if selectedProject != nil, env.activeWorkspace == nil {
                selectedProject = nil
            }
        }
        .alert("Error", isPresented: .init(
            get: { env.appError != nil },
            set: { if !$0 { env.appError = nil } }
        )) {
            Button("OK") { env.appError = nil }
        } message: {
            if let error = env.appError {
                Text(error.message)
            }
        }
        .keyboardShortcut("1", modifiers: [.command])
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.modifierFlags.contains(.command) {
                    switch event.keyCode {
                    case KeyCode.cmd1: selectedModule = .workspaces; return nil
                    case KeyCode.cmd2: selectedModule = .projects; return nil
                    case KeyCode.cmd3: selectedModule = .wiki; return nil
                    case KeyCode.cmd4: selectedModule = .git; return nil
                    case KeyCode.cmd5: selectedModule = .search; return nil
                    case KeyCode.cmd6: selectedModule = .requirements; return nil
                    case KeyCode.cmd7: selectedModule = .issues; return nil
                    case KeyCode.cmd8: selectedModule = .reports; return nil
                    case KeyCode.cmd9: selectedModule = .testing; return nil
                    case KeyCode.cmd0: selectedModule = .auditLog; return nil
                    default: break
                    }
                }
                return event
            }
        }
    }
}

enum SidebarModule: String, CaseIterable, Identifiable {
    case workspaces = "Workspaces"
    case projects = "Projects"
    case wiki = "Wiki"
    case git = "Git Browser"
    case search = "Search"
    case requirements = "Requirements"
    case issues = "Issues"
    case reports = "Reports"
    case testing = "Testing"
    case auditLog = "Activity Log"
    
    var id: String { self.rawValue }
    
    var iconName: String {
        switch self {
        case .workspaces: return "folder"
        case .projects: return "square.grid.3x3"
        case .wiki: return "doc.text"
        case .git: return "point.3.connected.trianglepath.dotted"
        case .search: return "magnifyingglass"
        case .requirements: return "doc.richtext"
        case .issues: return "ladybug"
        case .reports: return "chart.bar"
        case .testing: return "checklist"
        case .auditLog: return "clock.arrow.circlepath"
        }
    }
}
