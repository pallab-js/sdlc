import Foundation
import GRDB

public enum Status: String, Codable, CaseIterable, Identifiable, DatabaseValueConvertible, Sendable {
    case backlog = "BACKLOG"
    case todo = "TODO"
    case inProgress = "IN_PROGRESS"
    case inReview = "IN_REVIEW"
    case done = "DONE"
    
    public var id: String { self.rawValue }
    
    public var displayName: String {
        switch self {
        case .inProgress: return "In Progress"
        case .inReview: return "In Review"
        default: return self.rawValue.capitalized
        }
    }
}
