import Foundation
import GRDB

public struct ValidationError: Error, LocalizedError {
    public let message: String
    public init(_ message: String) { self.message = message }
    public var errorDescription: String? { message }
}

public struct InputValidator {
    public static func validateName(_ name: String, fieldName: String = "Name") throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ValidationError("\(fieldName) cannot be empty.")
        }
        guard trimmed.count <= 200 else {
            throw ValidationError("\(fieldName) must be 200 characters or less.")
        }
    }
    
    public static func validateDescription(_ description: String, maxLength: Int = 5000) throws {
        guard description.count <= maxLength else {
            throw ValidationError("Description must be \(maxLength) characters or less.")
        }
    }
    
    public static func validatePath(_ path: String) throws {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ValidationError("Path cannot be empty.")
        }
        guard FileManager.default.fileExists(atPath: trimmed) else {
            throw ValidationError("The specified directory does not exist.")
        }
    }
}
