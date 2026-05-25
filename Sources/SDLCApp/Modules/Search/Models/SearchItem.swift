import Foundation

public struct SearchItem: Identifiable, Codable, Sendable {
    public var id: UUID
    public var type: String
    public var title: String
    public var snippet: String
    
    public init(id: UUID = UUID(), type: String, title: String, snippet: String) {
        self.id = id
        self.type = type
        self.title = title
        self.snippet = snippet
    }
}
