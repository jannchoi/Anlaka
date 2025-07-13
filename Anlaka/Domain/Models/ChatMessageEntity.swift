import Foundation

struct ChatMessageDTO: Codable {
    let chatID: String
    let roomID: String
    let content: String
    let createdAt: String
    let updatedAt: String
    let sender: SenderDTO
    let files: [String]

    enum CodingKeys: String, CodingKey {
        case chatID = "chat_id"
        case roomID = "room_id"
        case content
        case createdAt
        case updatedAt
        case sender
        case files
    }
}

struct SenderDTO: Codable {
    let userID: String
    let nick: String
    let name: String
    let introduction: String
    let profileImage: String
    let hashTags: [String]

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case nick
        case name
        case introduction
        case profileImage
        case hashTags
    }
}
struct ChatMessageEntity: Codable {
    let chatID: String
    let roomID: String
    let content: String
    let createdAt: String
    let updatedAt: String
    let sender: SenderEntity
    let files: [String]

    enum CodingKeys: String, CodingKey {
        case chatID = "chat_id"
        case roomID = "room_id"
        case content
        case createdAt
        case updatedAt
        case sender
        case files
    }
    
    var isMine: Bool {
        if let userInfo = UserDefaultsManager.shared.getObject(forKey: .profileData, as: MyProfileInfoEntity.self) {
            return sender.userID == userInfo.userid
        }
        return false
    }
}

struct SenderEntity: Codable {
    let userID: String
    let nick: String
    let name: String
    let introduction: String
    let profileImage: String
    let hashTags: [String]

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case nick
        case name
        case introduction
        case profileImage
        case hashTags
    }
}

extension ChatMessageDTO {
    func toEntity() -> ChatMessageEntity {
        return ChatMessageEntity(
            chatID: self.chatID,
            roomID: self.roomID,
            content: self.content,
            createdAt: self.createdAt,
            updatedAt: self.updatedAt,
            sender: self.sender.toEntity(),
            files: self.files
        )
    }
}

extension SenderDTO {
    func toEntity() -> SenderEntity {
        return SenderEntity(
            userID: self.userID,
            nick: self.nick,
            name: self.name,
            introduction: self.introduction,
            profileImage: self.profileImage,
            hashTags: self.hashTags
        )
    }
}
