import Foundation

public struct GitCommit: Identifiable, Codable, Sendable {
    public var id: String { hash }
    public var hash: String
    public var author: String
    public var email: String
    public var date: Date
    public var message: String
    
    public init(hash: String, author: String, email: String, date: Date, message: String) {
        self.hash = hash
        self.author = author
        self.email = email
        self.date = date
        self.message = message
    }
}
