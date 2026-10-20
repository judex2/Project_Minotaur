import Foundation

nonisolated struct ActivityNotification: Codable, Identifiable {
    enum Kind: String, Codable { case memberJoined, creatorPost, reply }
    var id: String
    var kind: Kind
    var labyrinthID: UUID
    var postID: UUID? = nil
    var title: String
    var createdAt: Date
    var isDemo = false

    var icon: String {
        switch kind {
        case .memberJoined: return "person.badge.plus"
        case .creatorPost: return "megaphone"
        case .reply: return "bubble.left.and.bubble.right"
        }
    }
}
