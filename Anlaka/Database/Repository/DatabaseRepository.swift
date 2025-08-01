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
    
    // MARK: - Chat Pagination (New)
    func getMessagesCount(roomId: String) async throws -> Int
    func getMessagesBeforeDate(roomId: String, date: Date, limit: Int) async throws -> [ChatEntity]
    func getMessagesInDateRange(roomId: String, from: Date, to: Date) async throws -> [ChatEntity]
    func deleteMessagesBeforeDate(roomId: String, date: Date) async throws
    
    // MARK: - User
    func updateUserId(oldUserId: String, newUserId: String) async throws
    func isUserExists(userId: String) async throws -> Bool
    func getOpponentProfile(roomId: String, opponentId: String) async throws -> OpponentEntity?
    
    // MARK: - Database
    func resetDatabase() async throws
} 