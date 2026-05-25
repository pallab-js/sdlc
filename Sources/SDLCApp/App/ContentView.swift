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
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 180, ideal: 220)
            
            // Workspace status bar at the bottom of the sidebar
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Divider()
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.indigo)
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
                WikiView()
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
