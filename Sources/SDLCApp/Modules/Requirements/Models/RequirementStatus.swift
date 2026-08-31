import Foundation
import GRDB

public enum RequirementStatus: String, Codable, CaseIterable, Identifiable, DatabaseValueConvertible, Sendable {
    case draft = "DRAFT"
    case proposed = "PROPOSED"
    case approved = "APPROVED"
    case implemented = "IMPLEMENTED"
    
    public var id: String { self.rawValue }
    
    public var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .proposed: return "Proposed"
        case .approved: return "Approved"
        case .implemented: return "Implemented"
        }
    }
}
