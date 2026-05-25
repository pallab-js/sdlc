import Foundation

public protocol GitRepositoryProtocol {
    func getCommits(repoPath: String) async throws -> [GitCommit]
    func getStatus(repoPath: String) async throws -> String
}

public final class GitRepository: GitRepositoryProtocol, Sendable {
    private let gitService: GitService

    public init(gitService: GitService) {
        self.gitService = gitService
    }

    public func getCommits(repoPath: String) async throws -> [GitCommit] {
        try gitService.getCommits(repoPath: repoPath)
    }

    public func getStatus(repoPath: String) async throws -> String {
        try gitService.getStatus(repoPath: repoPath)
    }
}
