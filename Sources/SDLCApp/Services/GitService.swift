import Foundation

public enum GitServiceError: Error, LocalizedError {
    case notAGitRepository
    case commandFailed(Int, String)
    case outputEncodingFailed
    
    public var errorDescription: String? {
        switch self {
        case .notAGitRepository:
            return "The directory is not a Git repository."
        case .commandFailed(let code, let output):
            return "Git command failed (exit \(code)): \(output)"
        case .outputEncodingFailed:
            return "Failed to decode Git command output."
        }
    }
}

public final class GitService: Sendable {
    public init() {}
    
    @discardableResult
    private func runGitCommand(args: [String], directory: String) throws -> String {
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        process.arguments = args
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.currentDirectoryURL = URL(fileURLWithPath: directory)
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        pipe.fileHandleForReading.closeFile()
        
        guard let output = String(data: data, encoding: .utf8) else {
            throw GitServiceError.outputEncodingFailed
        }
        
        if process.terminationStatus != 0 {
            throw GitServiceError.commandFailed(Int(process.terminationStatus), output.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        
        return output
    }
    
    public func getStatus(repoPath: String) throws -> String {
        return try runGitCommand(args: ["status"], directory: repoPath)
    }
    
    public func getCommits(repoPath: String, limit: Int = 50) throws -> [GitCommit] {
        let format = "%H|%an|%ae|%ct|%s"
        let output = try runGitCommand(args: ["log", "--pretty=format:\(format)", "-n", "\(limit)"], directory: repoPath)
        
        var commits = [GitCommit]()
        let lines = output.components(separatedBy: "\n")
        for line in lines where !line.isEmpty {
            let parts = line.components(separatedBy: "|")
            guard parts.count == 5 else { continue }
            let hash = parts[0]
            let author = parts[1]
            let email = parts[2]
            let timestampString = parts[3]
            let message = parts[4]
            
            let date: Date
            if let timestamp = Double(timestampString) {
                date = Date(timeIntervalSince1970: timestamp)
            } else {
                date = Date()
            }
            
            commits.append(GitCommit(hash: hash, author: author, email: email, date: date, message: message))
        }
        return commits
    }
    
    public func getDiff(repoPath: String, commitHash: String) throws -> String {
        return try runGitCommand(args: ["show", "--stat", "--patch", commitHash], directory: repoPath)
    }
    
    public func getBranches(repoPath: String) throws -> [String] {
        let output = try runGitCommand(args: ["branch", "--format=%(refname:short)"], directory: repoPath)
        return output.components(separatedBy: "\n").filter { !$0.isEmpty }
    }
    
    public func getCurrentBranch(repoPath: String) throws -> String {
        let output = try runGitCommand(args: ["branch", "--show-current"], directory: repoPath)
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
