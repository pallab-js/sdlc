# Contributing to Offline SDLC Platform

Thank you for contributing! Since this project is offline-first and runs locally, here are the guidelines you should follow.

## Development Principles

1.  **Keep it Simple:** Avoid building unnecessary layers or pulling in external web-view wrappers. Keep dependency footprint minimal.
2.  **Spec-First:** Design your module structure first, then implement.
3.  **Strict MVVM:** Keep view code declarative and keep logic out of views.

## Git Branch Strategy

*   `main`: Stable production releases.
*   `develop`: Integration branch for features.
*   `feature/*`: Individual feature branches.
*   `hotfix/*`: Production hotfixes.

## Definition of Done

Before submitting a PR, make sure:
- [ ] Code builds successfully with `swift build`.
- [ ] All unit and integration tests pass via `swift test`.
- [ ] The schema migration runs successfully if changes are made to models.
- [ ] UI works natively on macOS (verified via manual testing).
