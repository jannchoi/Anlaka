import Foundation

struct ChatMessageDTO: Codable {
    let chatID: String?
    let roomID: String?
    let content: String?
    let createdAt: String?
    let updatedAt: String?
    let sender: SenderDTO?
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
    let name: String?
    let introduction: String?
    let profileImage: String?
    let hashTags: [String]?

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
    let sender: String
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
            return sender == userInfo.userid
        }
        return false
    }
}

extension ChatMessageDTO {
    func toEntity() -> ChatMessageEntity? {
        guard let chatID = chatID, let roomID = roomID, let sender = sender else {return nil}
        
        // 현재 시간을 ISO8601 형식으로 생성
        let currentTime = ISO8601DateFormatter().string(from: Date())
        
        return ChatMessageEntity(
            chatID: chatID,
            roomID: roomID,
            content: content ?? "",
            createdAt: createdAt ?? currentTime,
            updatedAt: updatedAt ?? currentTime,
            sender: sender.userID,
            files: self.files
        )
    }
}

