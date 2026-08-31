# SDLC App

**Offline-first, native macOS SDLC management platform.** No cloud. No subscriptions. Your data stays on your machine.

Built with Swift 6 + SwiftUI. SQLite via GRDB.swift. Full-text search with FTS5. 43 tests passing.

## Features

| Module | Description |
|--------|-------------|
| **Workspaces** | Isolated project containers with directory mapping |
| **Projects** | Epics and milestones with status/priority tracking |
| **Tasks** | 5-column Kanban board (Backlog → Done) with drag-and-drop status changes |
| **Issues** | Bug lifecycle tracking with severity, priority, and status |
| **Requirements** | Product requirement management (Draft → Implemented) |
| **Wiki** | Offline Markdown wiki with live preview via MarkdownUI |
| **Git Browser** | Commit history, branch list, and diff viewer |
| **Search** | FTS5 full-text search across all 6 entity types |
| **Reports** | Workspace-level metrics with completion progress ring |
| **Activity Log** | Immutable audit trail for all CRUD operations |
| **Export/Import** | JSON-based workspace portability |

## Architecture

```
SwiftUI Views → ViewModels (@MainActor) → Repositories (Protocol + GRDB) → SQLite (FTS5)
```

- **MVVM** with strict separation — no business logic in views
- **Dependency injection** via `AppEnvironment` container
- **Async/await** throughout — all DB queries off main thread
- **Soft deletion** across all entities with `SoftDeletable` protocol
- **Audit logging** on every create/update/delete operation
- **FTS5 sync triggers** for automatic search index maintenance

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Language | Swift 6.0 |
| UI | SwiftUI (macOS 14+) |
| Database | SQLite via GRDB.swift 6.29 |
| Markdown | swift-markdown-ui 2.4 |
| Logging | swift-log 1.15 |
| Testing | swift-testing 0.99 |

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

43 tests covering:
- Database migrations (all 16 migrations apply cleanly)
- Repository CRUD for all entity types
- Soft-delete filtering on `fetch(id:)`
- Full-text search (by name, description, all entity types)
- Audit log workspace isolation and ordering
- Report generation with soft-delete respect
- Input validation (empty, whitespace, length limits)
- Workspace export/import round-trip

## Project Structure

```
Sources/SDLCApp/
├── App/                    # Entry point, environment, keyboard shortcuts
├── Core/BaseTypes/         # Timestamped, SoftDeletable protocols
├── Database/               # GRDB migrations (16 total, including FTS5 triggers)
├── Modules/
│   ├── AuditLog/           # Activity log views and viewmodel
│   ├── Git/                # Git CLI wrapper and browser UI
│   ├── Issues/             # Bug tracking
│   ├── Projects/           # Project management
│   ├── Reports/            # Workspace metrics
│   ├── Requirements/       # Requirement lifecycle
│   ├── Search/             # FTS5 search
│   ├── Tasks/              # Kanban board
│   ├── Testing/            # Test case management
│   ├── Wiki/               # Markdown wiki
│   └── Workspace/          # Workspace CRUD
├── Services/               # AuditLog, Git, Search, Validation, SeedData, Export
└── Shared/                 # Status, Priority, Severity enums + reusable UI
```

## License

MIT
