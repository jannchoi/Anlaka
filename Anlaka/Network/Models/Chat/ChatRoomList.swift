

struct ChatRoomListResponseDTO: Codable {
    let data: [ChatRoomResponseDTO]
    
    func toEntity() -> ChatRoomListEntity {
        return ChatRoomListEntity(rooms: data.map { $0.toEntity() })
    }
}

struct ChatRoomListEntity {
    let rooms: [ChatRoomEntity]
}
