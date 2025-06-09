


struct ChatRoomRequestDTO: Codable {
    let opponentId: String

}

struct ChatRoomResponseDTO: Codable {
    let roomId: String
    let createdAt: String
    let updatedAt: String
    let participants: [UserInfoResponseDTO]
    let lastChat: ChatResponseDTO?
    
    func toEntity() -> ChatRoomEntity {
        return ChatRoomEntity(
            roomId: roomId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            participants: participants.map { $0.toEntity() },
            lastChat: lastChat?.toEntity()
        )
    }
}

struct ChatRoomEntity {
    let roomId: String
    let createdAt: String
    let updatedAt: String
    let participants: [UserInfoEntity]
    let lastChat: ChatEntity?
}
