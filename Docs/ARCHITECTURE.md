# System Architecture — Offline-First SDLC Platform

This document describes the system architecture, directory organization, state management, and design patterns utilized in the Offline-First SDLC Platform.

---

## High-Level Architecture

The platform is designed as a native modular monolith operating on top of a local SQLite database and the local filesystem.

```
+--------------------------------------------------+
|               SwiftUI Presentation               |
|  - Declarative macOS native UI Views            |
|  - Modern NavigationSplitView Sidebar layout    |
+--------------------------------------------------+
                         |
                         v
+--------------------------------------------------+
|                ViewModels (MVVM)                 |
|  - Manage UI state and handle user actions      |
|  - Fetch/store data asynchronously via async/await|
+--------------------------------------------------+
                         |
                         v
+--------------------------------------------------+
|                 Repository Layer                 |
|  - Interfaces for module CRUD operations         |
|  - Decouple view models from raw database logic |
+--------------------------------------------------+
                         |
                         v
+--------------------------------------------------+
|             Database & Storage Services          |
|  - GRDB.swift SQLite queue                       |
|  - Local File System storage & Git processes     |
+--------------------------------------------------+
```

---

## Core Modules & Boundaries

Every module resides in its own package subdirectory under `Sources/SDLCApp/Modules/` and owns:
- **Models**: Database record mappings and domain entities.
- **Repositories**: Data access objects.
- **ViewModels**: Presentation logic.
- **Views**: Declarative SwiftUI UI.

| Module Name | Responsibility |
|---|---|
| **Workspace** | Manages local project workspaces (directories and SQLite paths). |
| **Projects** | Organizes epics, milestones, and high-level project metadata. |
| **Tasks** | Manages task boards, boards status tracking, and subtasks. |
| **Requirements** | Authoring and tracing of software requirements specifications. |
| **Issues** | Standard issue tracking lifecycle for bugs and enhancements. |
| **Wiki** | Local Markdown wiki engine using MarkdownUI rendering. |
| **Git** | Shell wrapper for Git repository browser and commit history. |
| **Search** | Full-text indexing and search via SQLite FTS5 extension. |
| **Reports** | Analytics and summaries of project progression. |
| **Testing** | Creation and execution tracking of system test cases. |

---

## Architectural Rules

1. **Strict MVVM Boundary**: Under no circumstances should views perform DB queries or write business logic.
2. **Dependency Injection**: Use explicit initializers with repositories injected into view models rather than static shared singletons.
3. **Compilation Safety**: Avoid placeholders in compiled Swift files. Implement robust fallback error states.
4. **Concurrency**: All database queries must be executed off the main thread using `async/await`.
