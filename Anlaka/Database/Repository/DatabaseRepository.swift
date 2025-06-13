import Foundation

protocol DatabaseRepository {
    // MARK: - ChatRoom
    func saveChatRooms(_ rooms: [ChatRoomEntity]) async throws
    func getChatRooms() async throws -> [ChatRoomEntity]
    func updateChatRoom(_ room: ChatRoomEntity) async throws
    func deleteChatRoom(roomId: String) async throws
    
    // MARK: - Chat
    func saveMessages(_ messages: [ChatEntity]) async throws
    func saveMessage(_ message: ChatEntity) async throws
    func getMessages(roomId: String) async throws -> [ChatEntity]
    func getMessages(roomId: String, from date: Date) async throws -> [ChatEntity]
    func deleteMessages(roomId: String) async throws
    func getLastMessageDate(roomId: String) async throws -> Date?
    func isUserInChatRoom(roomId: String, userId: String) async throws -> Bool
    
    // MARK: - User
    func updateUserId(oldUserId: String, newUserId: String) async throws
    func isUserExists(userId: String) async throws -> Bool
    
    // MARK: - Database
    func resetDatabase() async throws
} 