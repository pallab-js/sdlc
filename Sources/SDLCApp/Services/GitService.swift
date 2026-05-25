import Foundation

public final class GitService: Sendable {
    public init() {}
    
    @discardableResult
    private func runGitCommand(args: [String], directory: String) throws -> String {
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        process.arguments = args
        process.launchPath = "/usr/bin/git"
        process.currentDirectoryPath = directory
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "GitServiceError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to read command output"])
        }
        
        if process.terminationStatus != 0 {
            throw NSError(domain: "GitServiceError", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: output])
        }
        
        return output
    }
    
    public func getStatus(repoPath: String) throws -> String {
        return try runGitCommand(args: ["status"], directory: repoPath)
    }
    
    public func getCommits(repoPath: String, limit: Int = 50) throws -> [GitCommit] {
        let format = "%H|%an|%ae|%ct|%s"
        do {
            let output = try runGitCommand(args: ["log", "--pretty=format:\(format)", "-n", "\(limit)"], directory: repoPath)
            
            var commits = [GitCommit]()
            let lines = output.components(separatedBy: "\n")
            for line in lines {
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
        } catch {
            // If the folder is not a git repo or log command fails, return empty list instead of crashing
            return []
        }
    }
}
