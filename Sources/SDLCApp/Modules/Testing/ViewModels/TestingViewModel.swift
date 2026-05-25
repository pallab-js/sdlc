import Foundation

@MainActor
public class TestingViewModel: ObservableObject {
    private let env: AppEnvironment

    @Published public var testCases: [TestCase] = []
    @Published public var testCaseInput = TestCaseInput()
    @Published public var requirements: [Requirement] = []
    @Published public var isShowingCreateSheet = false
    @Published public var showError = false
    @Published public var errorMessage = ""

    public struct TestCaseInput {
        public var title = ""
        public var description = ""
        public var expectedResult = ""
        public var requirementId: UUID?

        public init() {}
    }

    public init(env: AppEnvironment) {
        self.env = env
    }

    public func loadTestCases(workspaceId: UUID) async {
        do {
            testCases = try await env.testingRepository.fetchAll(forWorkspace: workspaceId)
        } catch {
            env.logger.error("Failed to load test cases: \(error)")
        }
    }

    public func loadRequirements(workspaceId: UUID) async {
        do {
            requirements = try await env.requirementRepository.fetchAll(forWorkspace: workspaceId)
        } catch {
            env.logger.error("Failed to load requirements: \(error)")
        }
    }

    public func createTestCase(workspaceId: UUID) async {
        guard !testCaseInput.title.isEmpty else {
            errorMessage = "Test case title cannot be empty."
            showError = true
            return
        }

        let newTestCase = TestCase(
            requirementId: testCaseInput.requirementId,
            title: testCaseInput.title,
            description: testCaseInput.description,
            expectedResult: testCaseInput.expectedResult
        )

        do {
            try await env.testingRepository.insert(newTestCase)
            try await env.auditLogService.log(
                workspaceId: workspaceId,
                action: "CREATE",
                entityType: "TestCase",
                entityId: newTestCase.id,
                details: "Created test case: \(newTestCase.title)"
            )
            await loadTestCases(workspaceId: workspaceId)

            testCaseInput = TestCaseInput()
        } catch {
            env.logger.error("Failed to create test case: \(error)")
            errorMessage = "Failed to create test case."
            showError = true
        }
    }

    public func deleteTestCase(_ testCase: TestCase, workspaceId: UUID) async {
        do {
            try await env.testingRepository.delete(testCase)
            try await env.auditLogService.log(
                workspaceId: workspaceId,
                action: "DELETE",
                entityType: "TestCase",
                entityId: testCase.id,
                details: "Deleted test case: \(testCase.title)"
            )
            await loadTestCases(workspaceId: workspaceId)
        } catch {
            env.logger.error("Failed to delete test case: \(error)")
        }
    }
}
