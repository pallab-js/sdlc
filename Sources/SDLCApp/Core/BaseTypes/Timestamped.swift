import Foundation

public protocol Timestamped {
    var createdAt: Date { get set }
    var updatedAt: Date { get set }
}
