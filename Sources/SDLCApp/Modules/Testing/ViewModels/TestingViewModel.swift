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
            errorMessage = "Failed to load test cases: \(error.localizedDescription)"
            showError = true
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
        do {
            try InputValidator.validateName(testCaseInput.title, fieldName: "Test case title")
            try InputValidator.validateDescription(testCaseInput.description)
            try InputValidator.validateDescription(testCaseInput.expectedResult)
        } catch let error as ValidationError {
            errorMessage = error.message
            showError = true
            return
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            return
        }

        let newTestCase = TestCase(
            requirementId: testCaseInput.requirementId,
            title: testCaseInput.title.trimmingCharacters(in: .whitespacesAndNewlines),
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
            showError = false
        } catch {
            errorMessage = "Failed to create test case: \(error.localizedDescription)"
            showError = true
            env.logger.error("Failed to create test case: \(error)")
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
            errorMessage = "Failed to delete test case: \(error.localizedDescription)"
            showError = true
            env.logger.error("Failed to delete test case: \(error)")
        }
    }
}
