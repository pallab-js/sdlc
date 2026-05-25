import Foundation
import GRDB

public enum Priority: String, Codable, CaseIterable, Identifiable, DatabaseValueConvertible, Sendable {
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
    case critical = "CRITICAL"
    
    public var id: String { self.rawValue }
    
    public var displayName: String {
        self.rawValue.capitalized
    }
}
