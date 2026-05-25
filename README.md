# SDLC App

**Offline-first, native macOS SDLC (Software Development Life Cycle) management platform.**

Built with Swift + SwiftUI. All data stored locally in SQLite. No cloud dependencies.

## Features

- **Workspaces** — Organize projects into isolated workspaces
- **Projects** — Manage epics, milestones, and tasks per workspace
- **Tasks** — Kanban-style task boards with status and priority tracking
- **Issues & Bugs** — Track bugs with severity, priority, and lifecycle management
- **Requirements** — Capture and trace product requirements
- **Wiki** — Offline Markdown wiki with preview rendering
- **Git Browser** — Browse commit history and repository status
- **Search** — Full-text search across all entities
- **Reporting** — Workspace-level metrics and progress tracking
- **Activity Log** — Immutable audit trail for all operations

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Language | Swift |
| UI Framework | SwiftUI |
| Database | SQLite (GRDB.swift) |
| Markdown | swift-markdown-ui |
| Logging | swift-log |

## Requirements

- macOS 14+ (Sonoma)
- Xcode 15+ or Swift 6.0 toolchain

## Build & Run

```bash
git clone https://github.com/pallab-js/sdlc.git
cd sdlc
swift run
```

## Run Tests

```bash
swift test
```

## License

MIT
