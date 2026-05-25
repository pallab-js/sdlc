# Offline-First SDLC Platform — AI-Driven Development Blueprint

> **A native, offline-first, open-source SDLC platform for macOS — built with Swift + SwiftUI.**

---

## Table of Contents

1. [Vision & Philosophy](#1-vision--philosophy)
2. [System Architecture](#2-system-architecture)
3. [Module Scope](#3-module-scope)
4. [MVP Definition](#4-mvp-definition)
5. [Technology Stack](#5-technology-stack)
6. [Repository & Directory Structure](#6-repository--directory-structure)
7. [Architectural Rules](#7-architectural-rules)
8. [Database Architecture](#8-database-architecture)
9. [UI/UX Architecture](#9-uiux-architecture)
10. [Performance & Security Requirements](#10-performance--security-requirements)
11. [AI-Assisted Development Workflow](#11-ai-assisted-development-workflow)
12. [Spec-Driven Development Workflow](#12-spec-driven-development-workflow)
13. [AI Prompting Standards](#13-ai-prompting-standards)
14. [Anti-Hallucination Framework](#14-anti-hallucination-framework)
15. [Testing Strategy](#15-testing-strategy)
16. [Documentation & Open-Source Standards](#16-documentation--open-source-standards)
17. [Release & Migration Engineering](#17-release--migration-engineering)
18. [Long-Term Roadmap](#18-long-term-roadmap)
19. [Production Readiness Checklist](#19-production-readiness-checklist)
20. [Recommended Execution Plan](#20-recommended-execution-plan)
21. [Core Engineering Principles](#21-core-engineering-principles)

---

## 1. Vision & Philosophy

### Vision

Build a fully offline-first, native macOS SDLC (Software Development Life Cycle) management platform. The platform must operate entirely without internet connectivity, store all data locally, support air-gapped environments, and remain lightweight and performant on low-resource systems.

**Primary development hardware:** MacBook Air M1 (8 GB RAM)

---

### Product Principles

| Principle | Rule |
|---|---|
| **Offline-First** | Never assume cloud access, SaaS APIs, remote auth, or internet connectivity |
| **Local Ownership** | Users own all source data, project files, documentation, backups, and Git repositories |
| **Native Performance** | No Electron, no webview-heavy architecture, no memory-heavy frameworks |
| **Minimal Complexity** | Avoid premature distributed systems, microservices, plugin engines, sync layers, or AI orchestration |
| **Modular Monolith** | Modular internally, monolithic operationally — simplifies AI generation, debugging, deployment, and maintenance |

---

## 2. System Architecture

### High-Level Stack

```
SwiftUI Desktop Application
         ↓
   Application Layer
         ↓
    Domain Modules
         ↓
   Repository Layer
         ↓
SQLite + Filesystem + Git
```

### Design Pattern: MVVM + Repository

```
SwiftUI View
     ↓
 ViewModel
     ↓
 Repository
     ↓
Database Service
```

### State Management

**Use:**
- `ObservableObject`, `@StateObject`
- `@EnvironmentObject` (sparingly)
- `async/await` for all async work

**Avoid:**
- Massive shared global state
- Unbounded reactive chains
- Excessive global stores

---

## 3. Module Scope

### Core Modules (Full Product)

| # | Module | Key Features |
|---|---|---|
| 1 | **Workspace Management** | Create/open workspaces, project organization, local metadata, archive/import/export |
| 2 | **Project Management** | Projects, epics, tasks, kanban boards, sprint tracking, milestones, labels, priorities |
| 3 | **Requirements Management** | Requirements, user stories, SRS support, traceability, versioning, task/test linkage |
| 4 | **Issue & Bug Tracking** | Bug lifecycle, severity, priority, attachments, reproduction steps, root cause notes |
| 5 | **Documentation & Wiki** | Markdown docs, internal wiki, local indexing, backlinks, versioned docs |
| 6 | **Git Integration** | Repository browser, branch visualization, commit history, diffs, repo status |
| 7 | **Test Management** | Test cases, test plans, execution status, requirement linkage, reporting |
| 8 | **Reporting** | Project summaries, sprint reports, issue metrics, traceability matrix, export support |
| 9 | **Search Engine** | Full-text search, indexed documents/issues/tasks, instant filtering, fuzzy search |
| 10 | **Audit Logging** | Immutable logs, entity history, activity tracking, local compliance logs |

---

## 4. MVP Definition

### v1.0 Must Include

- Workspace management
- Projects
- Tasks
- Issues
- Requirements
- Markdown Wiki
- Git browser
- Full-text search
- Local SQLite persistence

### Deferred to Post-v1

> Do **not** build these during MVP.

- Cloud sync or remote APIs
- Account systems or multi-user collaboration
- Plugin marketplace
- AI copilots
- CI/CD engines
- Distributed databases
- Complex automation systems

---

## 5. Technology Stack

| Layer | Technology |
|---|---|
| Language | Swift |
| UI Framework | SwiftUI |
| Database | SQLite |
| ORM / Persistence | GRDB.swift |
| Markdown Rendering | MarkdownUI |
| Charts | Swift Charts |
| Version Control | Git |
| Logging | swift-log |
| Package Manager | Swift Package Manager |
| Testing | XCTest |

---

## 6. Repository & Directory Structure

### GitHub Repository

```
offline-sdlc
```

### Branch Strategy

```
main
└── develop
    ├── feature/*
    └── hotfix/*
```

### Recommended Labels

`feature` · `bug` · `architecture` · `refactor` · `docs` · `performance` · `technical-debt` · `testing` · `good-first-issue`

### Project Directory Structure

```
SDLCApp/
├── App/                        # Entry point, app lifecycle
├── Core/                       # Core utilities, extensions, base types
├── Database/                   # GRDB setup, migrations, database service
├── Services/                   # Cross-module services (search, logging)
├── Modules/
│   ├── Workspace/
│   ├── Projects/
│   ├── Tasks/
│   ├── Requirements/
│   ├── Issues/
│   ├── Wiki/
│   ├── Git/
│   ├── Search/
│   ├── Reports/
│   └── Testing/
├── Shared/                     # Shared models, UI components, helpers
├── Resources/                  # Assets, fonts, localization
├── Scripts/                    # Build and utility scripts
├── Docs/                       # Architecture docs, specs, ADRs
└── Tests/                      # Unit, integration, UI tests
```

Each module owns: **Models · Repositories · ViewModels · Views · Services**

---

## 7. Architectural Rules

| Rule | Requirement |
|---|---|
| **No view logic** | Zero business logic inside SwiftUI Views |
| **Repository-only persistence** | All persistence goes through repositories |
| **Module ownership** | Every module owns its own models, repos, VMs, views, and services |
| **Declarative views** | Views must remain purely declarative |
| **No singleton abuse** | Avoid global singletons; prefer dependency injection |
| **No hidden side effects** | All side effects must be explicit and traceable |
| **Swift Concurrency** | All async work uses `async/await` — no completion handler sprawl |
| **Spec-driven** | Every feature begins with a written spec |

---

## 8. Database Architecture

### Database Rules

Every table must:
- Use UUIDs as primary keys
- Include `created_at` and `updated_at` timestamps
- Support schema migrations
- Support soft deletion where appropriate

### Core Tables

```sql
projects
requirements
tasks
issues
wiki_documents
test_cases
commits
activity_logs
attachments
sprints
```

### Example Entity Model

```swift
struct Task: Codable, FetchableRecord, PersistableRecord {
    var id: UUID
    var title: String
    var description: String
    var status: TaskStatus
    var createdAt: Date
    var updatedAt: Date
}
```

### Git Integration Strategy

**Phase 1 (MVP):** Git CLI wrappers — simpler, AI-friendly, reliable, minimal complexity.

**Phase 2 (Post-v1):** Optional migration to `libgit2` for richer native integration.

### Migration Rules

- Never modify existing migrations
- Always create new migrations for schema changes
- Test upgrades and support rollback where possible

---

## 9. UI/UX Architecture

### Layout Structure

```
Sidebar → Module Navigation → Content View → Detail Inspector
```

### Navigation

**Use:** `NavigationSplitView`, `NavigationStack`

**Avoid:** Deeply nested navigation hacks, excessive state-driven routing complexity

### Visual Design Goals

- Native macOS feel
- Lightweight and productivity-focused
- Keyboard-first interaction
- Full dark mode support
- Accessibility compliance

**Avoid:** Flashy animations, excessive gradients, web-app aesthetics

### Accessibility Requirements (Mandatory)

- VoiceOver support
- Full keyboard navigation
- Semantic accessibility labels
- Scalable typography

---

## 10. Performance & Security Requirements

### Performance Targets

| Metric | Target |
|---|---|
| Startup time | < 2 seconds |
| RAM usage (typical) | < 500 MB |
| Main thread blocking | Zero — all DB queries async |
| Search responsiveness | Responsive at 100k+ records |

### M1 Development Optimizations

Avoid running simultaneously: browser tab overload, Docker, multiple IDEs, large simulators.

Prefer: terminal workflows, incremental builds, lightweight editors (VS Code / Zed).

### Security Model

- Local-first security — zero telemetry
- No remote data transmission
- Encrypted exports (optional, future)
- Future: SQLCipher, encrypted vaults, signed exports

### Logging Standards

Log: `debug` · `warning` · `error` per module.

Never log: secrets, tokens, or private user content unnecessarily.

### Error Handling Standards

**Never:** silently fail, swallow errors, crash without context.

**Always:** surface recoverable errors to the user, log technical details, provide user-friendly error messages.

---

## 11. AI-Assisted Development Workflow

### Development Philosophy

> AI is an implementation accelerator. Humans control architecture, scope, design, correctness, and domain modeling.

| AI Assists With | Human Controls |
|---|---|
| Boilerplate and CRUD flows | Architecture decisions |
| Repetitive code patterns | Scope and feature design |
| Test scaffolding | Correctness validation |
| Documentation drafts | Domain modeling |

### Golden Rule

**Never ask AI to build entire systems at once.**

Always constrain to: one feature · one view model · one repository · one migration · one UI screen.

---

## 12. Spec-Driven Development Workflow

Every feature must follow this sequence before a single line of code is written:

```
1.  Write spec
2.  Define domain entities
3.  Define acceptance criteria
4.  Define persistence model
5.  Define UI states
6.  Define error cases
7.  Generate tasks
8.  Implement incrementally
9.  Write tests
10. Review
11. Commit
```

### Definition of Done

A feature is **DONE** only when all of the following are true:

- [ ] Spec complete
- [ ] Implementation complete
- [ ] Tests written and passing
- [ ] Manually verified
- [ ] Architecture-compliant
- [ ] Documented
- [ ] Committed cleanly

---

## 13. AI Prompting Standards

### Feature Implementation Prompt

```
Implement the [Module Name] module.

Requirements:
- Language: Swift
- Libraries: GRDB, SwiftUI, Foundation only
- Pattern: MVVM + repository
- Concurrency: async/await
- Production-ready: no placeholders, no invented APIs

Deliver:
- Model definition
- Repository with CRUD
- Database migration
- Unit tests
```

### Refactor Prompt

```
Refactor this module for readability, performance, lower memory usage,
and architecture consistency.

Do not change external behavior.
```

### Bugfix Prompt

```
Analyze the root cause of this crash.
Do not speculate.
Base conclusions only on: stack trace, supplied code, supplied logs.
```

---

## 14. Anti-Hallucination Framework

### Mandatory AI Safety Rules

**Rule 1 — Constrain Context**
Only provide: relevant files, current module, precise objective.
Never provide: full repo dumps or unrelated modules.

**Rule 2 — Require Deterministic Output**
Prompt AI: *"Do not invent APIs. Use only SwiftUI, Foundation, GRDB, and the existing project architecture."*

**Rule 3 — Demand Compilation Safety**
Prompt AI: *"Generate production-ready Swift code that compiles without placeholders."*

**Rule 4 — Require Explicit Assumptions**
Prompt AI: *"If assumptions are required, list them explicitly before generating code."*

**Rule 5 — Force Architectural Alignment**
Prompt AI: *"Follow MVVM and repository pattern exactly. Do not introduce new patterns."*

**Rule 6 — Demand Minimalism**
Prompt AI: *"Use the simplest correct implementation. Avoid unnecessary abstraction."*

**Rule 7 — Validate Every Output**
After every generation: compile → lint → test → manual review. Never trust AI output blindly.

**Rule 8 — Prevent Dependency Hallucinations**
Never allow AI to invent libraries, reference nonexistent APIs, or assume unsupported SwiftUI features.

**Rule 9 — Small Commit Strategy**
Commit after every stable change:
```bash
feat(tasks): implement task repository
fix(issues): resolve issue filtering bug
refactor(search): simplify indexing service
```

**Rule 10 — Maintain Architecture Document**
Keep `Docs/ARCHITECTURE.md` updated. AI must reference it before generating complex systems.

### AI Failure Red Flags

| Red Flag | Action |
|---|---|
| References unknown APIs | **STOP immediately** |
| Introduces factories, service locators, or unnecessary protocols | **REJECT** |
| Generates massive boilerplate with no clear value | **ROLL BACK** |
| Drifts from MVVM/repository pattern | **STOP AND REALIGN** |

---

## 15. Testing Strategy

### Required Test Coverage

| Layer | Test Type |
|---|---|
| Repositories | Unit tests |
| ViewModels | Unit tests |
| Services | Unit tests |
| Database operations | Integration tests |
| Schema migrations | Integration tests |
| Search indexing | Integration tests |
| Critical user workflows | UI tests (selective) |

### Continuous Validation Loop

After every feature:

```
Compile → Run tests → Manual smoke test → Architecture review → Performance review → Commit
```

---

## 16. Documentation & Open-Source Standards

### Mandatory Documents

| File | Purpose |
|---|---|
| `README.md` | Vision, screenshots, setup, roadmap, philosophy |
| `CONTRIBUTING.md` | How to contribute, coding standards |
| `ARCHITECTURE.md` | System design, patterns, module ownership |
| `ROADMAP.md` | Feature timeline and phase planning |
| `CHANGELOG.md` | Version history and migration notes |
| `LICENSE` | MIT or Apache 2.0 |

### Community Infrastructure

- Issue templates
- Pull request templates
- Contributor guidelines
- Coding standards document

### Recommended License

MIT or Apache 2.0

---

## 17. Release & Migration Engineering

### Release Checklist

Every release must include:

- [ ] Changelog updated
- [ ] Migration scripts validated
- [ ] Database backup verification
- [ ] Smoke test passing
- [ ] Performance review completed

### Backup Requirements

Users must be able to:
- Export workspaces
- Back up the local database
- Restore from backup
- Archive and import projects

---

## 18. Long-Term Roadmap

### Phase 1 — MVP (v1.0)
Workspace · Projects · Tasks · Issues · Requirements · Wiki · Git Browser · Search · SQLite Persistence

### Phase 2 — Extended Core
Test management · Reporting · Release tracking · Advanced Git support

### Phase 3 — Enterprise Readiness
LAN sync · Encrypted vaults · Enterprise auditing · Local AI integration (Ollama / llama.cpp)

### Phase 4 — Platform Expansion
Plugin architecture · Automation workflows · Distributed collaboration

### Future Local AI Features (Phase 3+)
- Issue summarization
- Requirement drafting
- Release note generation
- Commit explanation
- Search augmentation

*All AI features are optional enhancements — never core dependencies.*

---

## 19. Production Readiness Checklist

### Stability
- [ ] No critical crashes
- [ ] Migration stability verified
- [ ] Data corruption recovery tested

### Performance
- [ ] Startup time < 2 seconds
- [ ] RAM usage < 500 MB under typical load
- [ ] Search responsive at scale

### Security
- [ ] Zero telemetry confirmed
- [ ] Secure local storage reviewed
- [ ] Backup and restore system tested

### Maintainability
- [ ] Architecture docs complete and current
- [ ] All tests passing
- [ ] Linting passing
- [ ] Dead code removed

### UX
- [ ] Full keyboard navigation implemented
- [ ] Accessibility (VoiceOver) reviewed
- [ ] Onboarding flow validated

---

## 20. Recommended Execution Plan

| Week | Deliverables |
|---|---|
| **Week 1** | Repository setup, architecture docs, SQLite setup, app shell, sidebar navigation |
| **Week 2** | Projects module, Tasks module, repository layer, initial migrations |
| **Week 3** | Issues module, Requirements module, Markdown Wiki |
| **Week 4** | Search engine, Git integration, polishing, testing |
| **Week 5+** | Stabilization, performance optimization, accessibility, release preparation |

---

## 21. Core Engineering Principles

### Prioritize

**Simplicity · Determinism · Reliability · Maintainability · Offline Capability · Local Ownership · Native UX**

### Strategic Risk Register

The highest risks for this project are **not technical**:

| Risk | Mitigation |
|---|---|
| Uncontrolled scope creep | Hard MVP boundary; defer ruthlessly |
| Architectural drift | Regular architecture reviews; AI guardrails |
| AI-generated complexity | Small prompts; validate every output |
| Poor review discipline | Definition of Done enforced on every feature |
| Inconsistency across modules | Architecture doc as single source of truth |

### Final AI Governance

**Never allow AI to:**
- Redesign architecture arbitrarily
- Introduce hidden dependencies
- Generate unreviewed migrations
- Invent undocumented behavior
- Expand scope uncontrolled
- Bypass testing requirements

**Always require from AI:**
- Explicit reasoning and assumptions
- Architectural consistency
- Compilation safety
- Deterministic, minimal outputs
- Incremental implementation

---

*Built offline. Owned locally. Runs natively.*
