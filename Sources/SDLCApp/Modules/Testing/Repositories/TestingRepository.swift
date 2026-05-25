import Foundation
import GRDB

public protocol TestingRepositoryProtocol {
    func fetchAll(forRequirement requirementId: UUID) async throws -> [TestCase]
    func fetchAll(forWorkspace workspaceId: UUID) async throws -> [TestCase]
    func fetch(id: UUID) async throws -> TestCase?
    func insert(_ testCase: TestCase) async throws
    func update(_ testCase: TestCase) async throws
    func delete(_ testCase: TestCase) async throws
}

public final class TestingRepository: TestingRepositoryProtocol, Sendable {
    private let dbQueue: DatabaseQueue
    
    public init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }
    
    public func fetchAll(forRequirement requirementId: UUID) async throws -> [TestCase] {
        try await dbQueue.read { db in
            try TestCase
                .filter(Column("requirementId") == requirementId)
                .order(Column("createdAt").desc)
                .fetchAll(db)
        }
    }
    
    public func fetchAll(forWorkspace workspaceId: UUID) async throws -> [TestCase] {
        try await dbQueue.read { db in
            try TestCase.fetchAll(db, sql: """
                SELECT tc.* FROM test_cases tc
                LEFT JOIN requirements r ON tc.requirementId = r.id
                WHERE r.workspaceId = ?
                ORDER BY tc.createdAt DESC
            """, arguments: [workspaceId])
        }
    }
    
    public func fetch(id: UUID) async throws -> TestCase? {
        try await dbQueue.read { db in
            try TestCase.filter(Column("id") == id).fetchOne(db)
        }
    }

    public func insert(_ testCase: TestCase) async throws {
        let finalTestCase = testCase
        try await dbQueue.write { db in
            try finalTestCase.insert(db)
        }
    }
    
    public func update(_ testCase: TestCase) async throws {
        var updated = testCase
        updated.updatedAt = Date()
        let finalUpdated = updated
        try await dbQueue.write { db in
            try finalUpdated.update(db)
        }
    }
    
    public func delete(_ testCase: TestCase) async throws {
        let finalTestCase = testCase
        try await dbQueue.write { db in
            _ = try finalTestCase.delete(db)
        }
    }
}
