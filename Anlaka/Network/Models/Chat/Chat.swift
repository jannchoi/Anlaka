

struct ChatRequestDTO: Codable {
    let content: String
    let files: [String]?

}
struct ChatRequestEntity {
    let content: String
    let files: [String]?
    
    func toDTO() -> ChatRequestDTO {
        return ChatRequestDTO(content: content, files: files)
    }
}
struct ChatResponseDTO: Codable {
    let chatId: String
    let roomId: String
    let content: String
    let createdAt: String
    let updatedAt: String
    let sender: UserInfoResponseDTO
    let files: [String]

    enum CodingKeys: String, CodingKey {
        case chatId = "chat_id"
        case roomId = "room_id"
        case content
        case createdAt
        case updatedAt
        case sender
        case files
    }

    func toEntity() -> ChatEntity {
        return ChatEntity(
            chatId: chatId,
            roomId: roomId,
            content: content,
            createdAt: createdAt,
            updatedAt: updatedAt,
            sender: sender.userId,
            files: files
        )
    }
}


struct ChatEntity: Identifiable {
    let chatId: String
    let roomId: String
    let content: String
    let createdAt: String
    let updatedAt: String
    let sender: String
    let files: [String]
      
    var isMine: Bool {
        if let userInfo = UserDefaultsManager.shared.getObject(forKey: .profileData, as: MyProfileInfoEntity.self) {
            return sender == userInfo.userid
        }
        return false
    }
    var id: String {
        return chatId
    }
}
    
