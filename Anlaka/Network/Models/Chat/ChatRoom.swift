


struct ChatRoomRequestDTO: Codable {
    let opponent_id: String

}

struct ChatRoomResponseDTO: Codable {
    let roomId: String
    let createdAt: String
    let updatedAt: String
    let participants: [UserInfoResponseDTO]
    let lastChat: ChatResponseDTO?

    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case createdAt
        case updatedAt
        case participants
        case lastChat
    }

    func toEntity() -> ChatRoomEntity {
        let userInfos = participants.compactMap{$0.toEntity()}
        if roomId.isEmpty {
            print(" 채팅방 ID가 비어있습니다. roomId: \(roomId)")
        }
        return ChatRoomEntity(
            roomId: roomId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            participants: userInfos,
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
