import Foundation

public protocol GitRepositoryProtocol {
    func getCommits(repoPath: String) async throws -> [GitCommit]
    func getStatus(repoPath: String) async throws -> String
    func getDiff(repoPath: String, commitHash: String) async throws -> String
    func getBranches(repoPath: String) async throws -> [String]
    func getCurrentBranch(repoPath: String) async throws -> String
}

public final class GitRepository: GitRepositoryProtocol, Sendable {
    private let gitService: GitService

    public init(gitService: GitService) {
        self.gitService = gitService
    }

    public func getCommits(repoPath: String) async throws -> [GitCommit] {
        try await Task.detached(priority: .userInitiated) {
            try self.gitService.getCommits(repoPath: repoPath)
        }.value
    }

    public func getStatus(repoPath: String) async throws -> String {
        try await Task.detached(priority: .userInitiated) {
            try self.gitService.getStatus(repoPath: repoPath)
        }.value
    }
    
    public func getDiff(repoPath: String, commitHash: String) async throws -> String {
        try await Task.detached(priority: .userInitiated) {
            try self.gitService.getDiff(repoPath: repoPath, commitHash: commitHash)
        }.value
    }
    
    public func getBranches(repoPath: String) async throws -> [String] {
        try await Task.detached(priority: .userInitiated) {
            try self.gitService.getBranches(repoPath: repoPath)
        }.value
    }
    
    public func getCurrentBranch(repoPath: String) async throws -> String {
        try await Task.detached(priority: .userInitiated) {
            try self.gitService.getCurrentBranch(repoPath: repoPath)
        }.value
    }
}
