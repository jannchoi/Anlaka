

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
    
    func toEntity() -> ChatEntity {
        return ChatEntity(
            chatId: chatId,
            roomId: roomId,
            content: content,
            createdAt: createdAt,
            updatedAt: updatedAt,
            sender: sender.toEntity(),
            files: files
        )
    }
}

struct ChatEntity {
    let chatId: String
    let roomId: String
    let content: String
    let createdAt: String
    let updatedAt: String
    let sender: UserInfoEntity
    let files: [String]
}
    
