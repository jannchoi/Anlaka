


struct ChatListResponseDTO: Codable {
    let data: [ChatResponseDTO]
    
    func toEntity() -> ChatListEntity {
        return ChatListEntity(chats: data.map { $0.toEntity() })
    }
}

struct ChatListEntity {
    let chats: [ChatEntity]
}
