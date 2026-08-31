import Foundation
import GRDB
import Logging

public final class SeedDataService: Sendable {
    private let dbQueue: DatabaseQueue
    private let logger: Logger
    
    public init(dbQueue: DatabaseQueue, logger: Logger) {
        self.dbQueue = dbQueue
        self.logger = logger
    }
    
    public func seedAll() async throws {
        logger.info("Seeding database with sample data...")
        
        let ws1Id = UUID()
        let ws2Id = UUID()
        let now = Date()
        
        // MARK: - Workspaces
        let workspaces: [Workspace] = [
            Workspace(id: ws1Id, name: "E-Commerce Platform", path: "/Users/dev/ecommerce-platform", createdAt: now.addingTimeInterval(-86400 * 30), updatedAt: now),
            Workspace(id: ws2Id, name: "Mobile Banking App", path: "/Users/dev/mobile-banking", createdAt: now.addingTimeInterval(-86400 * 15), updatedAt: now)
        ]
        
        // MARK: - Projects
        let p1Id = UUID()
        let p2Id = UUID()
        let p3Id = UUID()
        let p4Id = UUID()
        
        let projects: [Project] = [
            Project(id: p1Id, workspaceId: ws1Id, name: "Frontend Redesign", description: "Complete UI overhaul with new design system based on Material Design 3 principles", status: .inProgress, priority: .high, createdAt: now.addingTimeInterval(-86400 * 25)),
            Project(id: p2Id, workspaceId: ws1Id, name: "Payment Gateway Integration", description: "Integrate Stripe and PayPal payment processing with PCI compliance", status: .todo, priority: .critical, createdAt: now.addingTimeInterval(-86400 * 20)),
            Project(id: p3Id, workspaceId: ws2Id, name: "Core Banking Module", description: "Fund transfer, balance inquiry, and account management features", status: .inReview, priority: .high, createdAt: now.addingTimeInterval(-86400 * 12)),
            Project(id: p4Id, workspaceId: ws2Id, name: "KYC Verification", description: "Identity verification system with document upload and facial recognition", status: .todo, priority: .medium, createdAt: now.addingTimeInterval(-86400 * 8))
        ]
        
        // MARK: - Requirements
        let r1Id = UUID()
        let r2Id = UUID()
        let r3Id = UUID()
        let r4Id = UUID()
        let r5Id = UUID()
        
        let requirements: [Requirement] = [
            Requirement(id: r1Id, workspaceId: ws1Id, title: "Responsive Navigation", description: "Navigation must adapt to mobile, tablet, and desktop viewports with hamburger menu on small screens", status: .approved),
            Requirement(id: r2Id, workspaceId: ws1Id, title: "Dark Mode Support", description: "Full dark mode support across all pages with automatic system preference detection", status: .implemented),
            Requirement(id: r3Id, workspaceId: ws1Id, title: "Accessibility WCAG 2.1 AA", description: "All UI components must meet WCAG 2.1 AA compliance including screen reader support", status: .proposed),
            Requirement(id: r4Id, workspaceId: ws2Id, title: "Biometric Login", description: "Support Face ID and Touch ID for quick and secure authentication", status: .approved),
            Requirement(id: r5Id, workspaceId: ws2Id, title: "Transaction History", description: "Display last 90 days of transaction history with filtering and export to CSV", status: .draft)
        ]
        
        // MARK: - Tasks
        let tasks: [ProjectTask] = [
            // Frontend Redesign tasks
            ProjectTask(projectId: p1Id, requirementId: r1Id, title: "Create responsive sidebar component", description: "Build a collapsible sidebar that transforms to bottom navigation on mobile", status: .done, priority: .high, dueDate: now.addingTimeInterval(-86400 * 5)),
            ProjectTask(projectId: p1Id, requirementId: r1Id, title: "Implement hamburger menu", description: "Add hamburger menu toggle with smooth slide animation for mobile breakpoints", status: .inProgress, priority: .high, dueDate: now.addingTimeInterval(86400 * 3)),
            ProjectTask(projectId: p1Id, requirementId: r2Id, title: "Set up color token system", description: "Define semantic color tokens for light/dark themes using CSS custom properties", status: .done, priority: .medium),
            ProjectTask(projectId: p1Id, requirementId: r2Id, title: "Migrate existing components to dark mode", description: "Update all 47 components to use the new color token system", status: .inProgress, priority: .medium, dueDate: now.addingTimeInterval(86400 * 10)),
            ProjectTask(projectId: p1Id, requirementId: r3Id, title: "Add ARIA labels to interactive elements", description: "Ensure all buttons, links, and form controls have proper ARIA attributes", status: .todo, priority: .high, dueDate: now.addingTimeInterval(86400 * 7)),
            ProjectTask(projectId: p1Id, requirementId: r3Id, title: "Implement keyboard navigation", description: "Tab order, focus trapping in modals, and keyboard shortcuts for power users", status: .backlog, priority: .medium),
            ProjectTask(projectId: p1Id, title: "Performance audit", description: "Run Lighthouse audit and fix all issues scoring below 90", status: .todo, priority: .low, dueDate: now.addingTimeInterval(86400 * 14)),
            
            // Payment Gateway tasks
            ProjectTask(projectId: p2Id, title: "Set up Stripe SDK", description: "Install and configure Stripe iOS SDK with test API keys", status: .todo, priority: .critical, dueDate: now.addingTimeInterval(86400 * 2)),
            ProjectTask(projectId: p2Id, title: "Implement card tokenization", description: "Securely tokenize credit card numbers using Stripe.js - never touch raw card data", status: .todo, priority: .critical),
            ProjectTask(projectId: p2Id, title: "Create payment confirmation flow", description: "Build order review screen, payment submission, and success/failure handling", status: .backlog, priority: .high),
            ProjectTask(projectId: p2Id, title: "Add PayPal fallback option", description: "Implement PayPal Smart Payment Buttons as alternative payment method", status: .backlog, priority: .medium),
            ProjectTask(projectId: p2Id, title: "PCI compliance documentation", description: "Document SAQ-A compliance requirements and complete self-assessment", status: .todo, priority: .high, dueDate: now.addingTimeInterval(86400 * 5)),
            
            // Core Banking tasks
            ProjectTask(projectId: p3Id, requirementId: r4Id, title: "Implement Face ID authentication", description: "Use LocalAuthentication framework for biometric verification on login", status: .done, priority: .high),
            ProjectTask(projectId: p3Id, title: "Build fund transfer screen", description: "Internal and external transfers with confirmation dialog and OTP verification", status: .inReview, priority: .critical, dueDate: now.addingTimeInterval(86400 * 1)),
            ProjectTask(projectId: p3Id, title: "Balance inquiry with mini statement", description: "Show current balance and last 10 transactions on home screen", status: .done, priority: .high),
            ProjectTask(projectId: p3Id, title: "Add transaction receipt generation", description: "Generate PDF receipts for completed transactions with share functionality", status: .inProgress, priority: .medium, dueDate: now.addingTimeInterval(86400 * 4)),
            ProjectTask(projectId: p3Id, requirementId: r5Id, title: "Build transaction history list", description: "Paginated list with pull-to-refresh, date range filter, and category filter", status: .todo, priority: .high),
            ProjectTask(projectId: p3Id, title: "CSV export functionality", description: "Allow users to export filtered transaction history as CSV file", status: .backlog, priority: .low),
            
            // KYC Verification tasks
            ProjectTask(projectId: p4Id, title: "Document upload camera integration", description: "Camera capture for ID documents with auto-edge detection and crop", status: .todo, priority: .high, dueDate: now.addingTimeInterval(86400 * 5)),
            ProjectTask(projectId: p4Id, title: "OCR text extraction", description: "Extract name, DOA, and ID number from uploaded documents using Vision framework", status: .backlog, priority: .medium),
            ProjectTask(projectId: p4Id, title: "Facial recognition matching", description: "Compare selfie with ID photo using on-device ML for identity verification", status: .backlog, priority: .high),
            ProjectTask(projectId: p4Id, title: "Admin review dashboard", description: "Web portal for compliance team to review and approve/reject KYC submissions", status: .backlog, priority: .medium)
        ]
        
        // MARK: - Issues
        let issues: [Issue] = [
            Issue(projectId: p1Id, title: "Sidebar flickers on resize", description: "When resizing browser window between breakpoints, the sidebar flickers momentarily. Reproduce by dragging window edge slowly.", status: .inProgress, priority: .high, severity: .medium),
            Issue(projectId: p1Id, title: "Dark mode contrast failure", description: "Secondary text color in dark mode has contrast ratio of 3.2:1, below WCAG AA 4.5:1 requirement", status: .todo, priority: .high, severity: .high),
            Issue(projectId: p1Id, title: "Mobile menu doesn't close on navigation", description: "After selecting an item from hamburger menu on iOS Safari, menu stays open", status: .todo, priority: .medium, severity: .low),
            Issue(projectId: p2Id, title: "Stripe webhook signature validation fails", description: "In production, webhook endpoint returns 400 for valid Stripe signatures. Possibly clock skew issue.", status: .todo, priority: .critical, severity: .blocker),
            Issue(projectId: p2Id, title: "PayPal button not rendering on Safari", description: "PayPal Smart Payment Buttons show blank space on Safari 17.2. Works on Chrome and Firefox.", status: .todo, priority: .high, severity: .high),
            Issue(projectId: p3Id, title: "Fund transfer OTP expired too quickly", description: "OTP expires in 30 seconds but SMS delivery takes 15-20 seconds, leaving barely 10 seconds for user input", status: .inProgress, priority: .high, severity: .medium),
            Issue(projectId: p3Id, title: "Balance shows stale data after transfer", description: "After successful transfer, balance on home screen doesn't refresh until manual pull-to-refresh", status: .todo, priority: .medium, severity: .medium),
            Issue(projectId: p4Id, title: "Camera permission crash on iOS 16", description: "App crashes when requesting camera permission on devices running iOS 16.0-16.3", status: .todo, priority: .critical, severity: .critical)
        ]
        
        // MARK: - Wiki Documents
        let wikiDocs: [WikiDocument] = [
            WikiDocument(workspaceId: ws1Id, title: "Architecture Decision Records", content: "# Architecture Decisions\n\n## ADR-001: Use React for Frontend\n- **Status**: Accepted\n- **Date**: 2024-01-15\n\n### Context\nWe need to choose a frontend framework for the e-commerce platform redesign.\n\n### Decision\nWe will use React 18 with TypeScript for the following reasons:\n- Large ecosystem of e-commerce component libraries\n- Team expertise and hiring market availability\n- Excellent performance with concurrent features\n\n### Consequences\n- Need to set up TypeScript configuration\n- Team needs training on React hooks patterns"),
            WikiDocument(workspaceId: ws1Id, title: "API Design Guidelines", content: "# REST API Design Guidelines\n\n## Naming Conventions\n- Use plural nouns: `/api/products`, `/api/orders`\n- Use kebab-case for multi-word: `/api/order-items`\n- Use query params for filtering: `/api/products?category=electronics`\n\n## Response Format\n```json\n{\n  \"data\": {},\n  \"meta\": {\n    \"page\": 1,\n    \"total\": 100\n  },\n  \"errors\": []\n}\n```\n\n## Versioning\nAll endpoints prefixed with `/api/v1/` for backward compatibility."),
            WikiDocument(workspaceId: ws2Id, title: "Security Protocols", content: "# Banking App Security Protocols\n\n## Authentication\n- JWT tokens with 15-minute expiry\n- Refresh tokens stored in Keychain\n- Biometric authentication via LocalAuthentication\n\n## Data Protection\n- All data encrypted at rest using AES-256\n- TLS 1.3 for all network communication\n- Certificate pinning for API endpoints\n\n## Session Management\n- Automatic logout after 5 minutes of inactivity\n- Single session per device\n- Remote session revocation capability"),
            WikiDocument(workspaceId: ws2Id, title: "Release Process", content: "# Release Process\n\n## Versioning\nWe follow Semantic Versioning (SemVer):\n- Major: Breaking changes\n- Minor: New features (backward compatible)\n- Patch: Bug fixes\n\n## Release Checklist\n1. All CI checks passing\n2. QA sign-off on staging\n3. Security scan completed\n4. Performance benchmarks within thresholds\n5. Product owner approval\n6. App Store submission (mobile)\n7. Monitor crash reports for 24h\n\n## Rollback\n- Maintain previous version binary\n- Database migrations must be reversible\n- Feature flags for gradual rollout")
        ]
        
        // MARK: - Test Cases
        let testCases: [TestCase] = [
            TestCase(requirementId: r1Id, title: "Nav collapses at 768px breakpoint", description: "Resize browser to 767px width", expectedResult: "Sidebar collapses and hamburger menu icon appears"),
            TestCase(requirementId: r1Id, title: "Hamburger menu opens sidebar", description: "Tap hamburger icon on mobile viewport", expectedResult: "Sidebar slides in from left with overlay"),
            TestCase(requirementId: r2Id, title: "System dark mode activates theme", description: "Toggle system appearance to Dark in System Settings", expectedResult: "App automatically switches to dark color scheme within 1 second"),
            TestCase(requirementId: r2Id, title: "Manual theme override persists", description: "Select dark mode in app settings, close and reopen app", expectedResult: "Dark mode preference is remembered across app launches"),
            TestCase(requirementId: r4Id, title: "Face ID login succeeds", description: "Tap login button when Face ID is available and enrolled", expectedResult: "Face ID prompt appears, successful scan logs user in"),
            TestCase(requirementId: r4Id, title: "Face ID fallback to passcode", description: "Tap login, then tap 'Use Passcode' on Face ID prompt", expectedResult: "System passcode entry screen appears"),
            TestCase(requirementId: r5Id, title: "Transaction history loads 90 days", description: "Navigate to transaction history", expectedResult: "List shows transactions from last 90 days, most recent first"),
            TestCase(requirementId: r5Id, title: "Filter by date range", description: "Select date range filter, set to last 7 days", expectedResult: "Only transactions within selected range are displayed"),
            TestCase(title: "Empty state for new workspace", description: "Create workspace with no projects", expectedResult: "Shows 'No Projects Found' with CTA to create first project"),
            TestCase(title: "Search across all entity types", description: "Search for 'payment' in workspace with projects, tasks, issues", expectedResult: "Results include matching items from all entity types with type badges")
        ]
        
        // MARK: - Activity Logs
        let activityLogs: [ActivityLog] = [
            ActivityLog(workspaceId: ws1Id, action: "CREATE", entityType: "Workspace", entityId: ws1Id.uuidString, details: "Created workspace: E-Commerce Platform", createdAt: now.addingTimeInterval(-86400 * 30)),
            ActivityLog(workspaceId: ws1Id, action: "CREATE", entityType: "Project", entityId: p1Id.uuidString, details: "Created project: Frontend Redesign", createdAt: now.addingTimeInterval(-86400 * 25)),
            ActivityLog(workspaceId: ws1Id, action: "CREATE", entityType: "Project", entityId: p2Id.uuidString, details: "Created project: Payment Gateway Integration", createdAt: now.addingTimeInterval(-86400 * 20)),
            ActivityLog(workspaceId: ws1Id, action: "CREATE", entityType: "Requirement", entityId: r1Id.uuidString, details: "Created requirement: Responsive Navigation", createdAt: now.addingTimeInterval(-86400 * 18)),
            ActivityLog(workspaceId: ws1Id, action: "UPDATE", entityType: "Task", entityId: UUID().uuidString, details: "Updated task status to DONE: Create responsive sidebar component", createdAt: now.addingTimeInterval(-86400 * 5)),
            ActivityLog(workspaceId: ws1Id, action: "CREATE", entityType: "Issue", entityId: UUID().uuidString, details: "Created issue: Sidebar flickers on resize", createdAt: now.addingTimeInterval(-86400 * 3)),
            ActivityLog(workspaceId: ws2Id, action: "CREATE", entityType: "Workspace", entityId: ws2Id.uuidString, details: "Created workspace: Mobile Banking App", createdAt: now.addingTimeInterval(-86400 * 15)),
            ActivityLog(workspaceId: ws2Id, action: "CREATE", entityType: "Project", entityId: p3Id.uuidString, details: "Created project: Core Banking Module", createdAt: now.addingTimeInterval(-86400 * 12)),
            ActivityLog(workspaceId: ws2Id, action: "UPDATE", entityType: "Task", entityId: UUID().uuidString, details: "Moved fund transfer screen to In Review", createdAt: now.addingTimeInterval(-86400 * 1)),
            ActivityLog(workspaceId: ws2Id, action: "CREATE", entityType: "Issue", entityId: UUID().uuidString, details: "Created issue: Camera permission crash on iOS 16", createdAt: now.addingTimeInterval(-3600 * 2))
        ]
        
        // MARK: - Insert all data
        try await dbQueue.write { db in
            for ws in workspaces { try ws.insert(db) }
            for project in projects { try project.insert(db) }
            for req in requirements { try req.insert(db) }
            for task in tasks { try task.insert(db) }
            for issue in issues { try issue.insert(db) }
            for doc in wikiDocs { try doc.insert(db) }
            for tc in testCases { try tc.insert(db) }
            for log in activityLogs { try log.insert(db) }
        }
        
        logger.info("Seed data inserted successfully: \(workspaces.count) workspaces, \(projects.count) projects, \(requirements.count) requirements, \(tasks.count) tasks, \(issues.count) issues, \(wikiDocs.count) wiki docs, \(testCases.count) test cases, \(activityLogs.count) activity logs")
    }
}
