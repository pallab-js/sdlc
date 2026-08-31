import Foundation

public protocol SoftDeletable {
    var deletedAt: Date? { get set }
    var isDeleted: Bool { get }
}

extension SoftDeletable {
    public var isDeleted: Bool {
        return deletedAt != nil
    }
}
