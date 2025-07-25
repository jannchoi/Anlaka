import Foundation
import RealmSwift

// MARK: - DatabaseRepository Factory
// internal 접근제어로 같은 모듈 내에서만 접근 가능
internal enum DatabaseRepositoryFactory {
    static func create() throws -> DatabaseRepository {
        return try DatabaseRepositoryImp()
    }
}

// MARK: - DatabaseRepository Implementation
// internal 접근제어로 같은 모듈 내에서만 접근 가능
internal final class DatabaseRepositoryImp: DatabaseRepository {
    private let configuration: Realm.Configuration
    
    init() throws {
        self.configuration = Realm.Configuration.defaultConfiguration
    }
    
    // MARK: - ChatRoom
    func saveChatRooms(_ rooms: [ChatRoomEntity]) async throws {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let realm = try Realm(configuration: configuration)
                let realmRooms = rooms.map { room -> ChatRoomRealmModel in
                    let lastChat = room.lastChat.map { chat -> ChatRealmModel in
                        ChatRealmModel(
                            chatId: chat.chatId,
                            content: chat.content,
                            createdAt: PresentationMapper.parseISO8601ToDate(chat.createdAt),
                            updatedAt: PresentationMapper.parseISO8601ToDate(chat.updatedAt),
                            senderId: chat.sender,
                            files: chat.files,
                            roomId: room.roomId
                        )
                    }
                    
                    let participants = room.participants.map { participant -> UserInfoRealmModel in
                        UserInfoRealmModel(
                            userId: participant.userId,
                            nick: participant.nick,
                            introduction: participant.introduction,
                            profileImage: participant.profileImage
                        )
                    }
                    
                    return ChatRoomRealmModel(
                        roomId: room.roomId,
                        lastChat: lastChat,
                        createdAt: PresentationMapper.parseISO8601ToDate(room.createdAt),
                        updatedAt: PresentationMapper.parseISO8601ToDate(room.updatedAt),
                        participants: participants
                    )
                }
                
                try realm.write {
                    realm.add(realmRooms, update: .modified)
                }
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func getChatRooms() async throws -> [ChatRoomEntity] {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let realm = try Realm(configuration: configuration)
                let realmRooms = realm.objects(ChatRoomRealmModel.self)
                let rooms = realmRooms.map { room -> ChatRoomEntity in
                    let lastChat = room.lastChat.map { chat -> ChatEntity in
                        ChatEntity(
                            chatId: chat.chatId,
                            roomId: room.roomId,
                            content: chat.content,
                            createdAt: PresentationMapper.formatDateToISO8601(chat.createdAt),
                            updatedAt: PresentationMapper.formatDateToISO8601(chat.updatedAt),
                            sender: chat.senderId,
                            files: Array(chat.files)
                        )
                    }
                    
                    let participants = room.participants.map { participant -> UserInfoEntity in
                        UserInfoEntity(
                            userId: participant.userId,
                            nick: participant.nick,
                            introduction: participant.introduction ?? "",
                            profileImage: participant.profileImage ?? ""
                        )
                    }
                    
                    return ChatRoomEntity(
                        roomId: room.roomId,
                        createdAt: "",
                        updatedAt: PresentationMapper.formatDateToISO8601(room.updatedAt),
                        participants: Array(participants),
                        lastChat: lastChat
                    )
                }
                continuation.resume(returning: Array(rooms))
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func updateChatRoom(_ room: ChatRoomEntity) async throws {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let realm = try Realm(configuration: configuration)
                let realmRoom = ChatRoomRealmModel(
                    roomId: room.roomId,
                    lastChat: room.lastChat.map { chat in
                        ChatRealmModel(
                            chatId: chat.chatId,
                            content: chat.content,
                            createdAt: PresentationMapper.parseISO8601ToDate(chat.createdAt),
                            updatedAt: PresentationMapper.parseISO8601ToDate(chat.updatedAt),
                            senderId: chat.sender,
                            files: chat.files,
                            roomId: room.roomId
                        )
                    },
                    createdAt: PresentationMapper.parseISO8601ToDate(room.createdAt),
                    updatedAt: PresentationMapper.parseISO8601ToDate(room.updatedAt),
                    participants: room.participants.map { participant in
                        UserInfoRealmModel(
                            userId: participant.userId,
                            nick: participant.nick,
                            introduction: participant.introduction,
                            profileImage: participant.profileImage
                        )
                    }
                )
                
                try realm.write {
                    realm.add(realmRoom, update: .modified)
                }
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func deleteChatRoom(roomId: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let realm = try Realm(configuration: configuration)
                
                // ChatRoomRealmModel 삭제
                if let room = realm.object(ofType: ChatRoomRealmModel.self, forPrimaryKey: roomId) {
                    try realm.write {
                        realm.delete(room)
                    }
                }
                
                // ChatListRealmModel 삭제
                if let chatList = realm.object(ofType: ChatListRealmModel.self, forPrimaryKey: roomId) {
                    try realm.write {
                        realm.delete(chatList)
                    }
                }
                
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Chat
    func saveMessages(_ messages: [ChatEntity]) async throws {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let realm = try Realm(configuration: configuration)
                
                try realm.write {
                    for message in messages {
                        // 중복 체크
                        if realm.object(ofType: ChatRealmModel.self, forPrimaryKey: message.chatId) != nil {
                            continue
                        }
                        
                        let realmMessage = ChatRealmModel(
                            chatId: message.chatId,
                            content: message.content,
                            createdAt: PresentationMapper.parseISO8601ToDate(message.createdAt),
                            updatedAt: PresentationMapper.parseISO8601ToDate(message.updatedAt),
                            senderId: message.sender,
                            files: message.files,
                            roomId: message.roomId
                        )
                        
                        // 채팅방 찾기 또는 생성
                        let chatList = realm.object(ofType: ChatListRealmModel.self, forPrimaryKey: message.roomId) ?? ChatListRealmModel(
                            roomId: message.roomId,
                            chats: [],
                            participants: []
                        )
                        
                        // 새로운 참여자 추가 (String으로)
                        if !chatList.participants.contains(message.sender) {
                            chatList.participants.append(message.sender)
                        }
                        
                        // 메시지 추가
                        chatList.chats.append(realmMessage)
                        
                        realm.add(chatList, update: .modified)
                    }
                }
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func saveMessage(_ message: ChatEntity) async throws {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let realm = try Realm(configuration: configuration)
                
                // 중복 체크
                if realm.object(ofType: ChatRealmModel.self, forPrimaryKey: message.chatId) != nil {
                    continuation.resume()
                    return
                }
                
                let realmMessage = ChatRealmModel(
                    chatId: message.chatId,
                    content: message.content,
                    createdAt: PresentationMapper.parseISO8601ToDate(message.createdAt),
                    updatedAt: PresentationMapper.parseISO8601ToDate(message.updatedAt),
                    senderId: message.sender,
                    files: message.files,
                    roomId: message.roomId
                )
                
                try realm.write {
                    // 채팅방 찾기 또는 생성
                    let chatList = realm.object(ofType: ChatListRealmModel.self, forPrimaryKey: message.roomId) ?? ChatListRealmModel(
                        roomId: message.roomId,
                        chats: [],
                        participants: []
                    )
                    
                    // 새로운 참여자 추가 (String으로)
                    if !chatList.participants.contains(message.sender) {
                        chatList.participants.append(message.sender)
                    }
                    
                    // 메시지 추가
                    chatList.chats.append(realmMessage)
                    
                    realm.add(chatList, update: .modified)
                }
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func getMessages(roomId: String) async throws -> [ChatEntity] {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let realm = try Realm(configuration: configuration)
                guard let chatList = realm.object(ofType: ChatListRealmModel.self, forPrimaryKey: roomId) else {
                    continuation.resume(returning: [])
                    return
                }
                
                let messages = chatList.chats.sorted(by: { $0.createdAt < $1.createdAt }).map { message -> ChatEntity in
                    return ChatEntity(
                        chatId: message.chatId,
                        roomId: roomId,
                        content: message.content,
                        createdAt: PresentationMapper.formatDateToISO8601(message.createdAt),
                        updatedAt: PresentationMapper.formatDateToISO8601(message.updatedAt),
                        sender: message.senderId,
                        files: Array(message.files)
                    )
                }
                continuation.resume(returning: Array(messages))
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func getMessages(roomId: String, from date: Date) async throws -> [ChatEntity] {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let realm = try Realm(configuration: configuration)
                let realmMessages = realm.objects(ChatRealmModel.self)
                    .filter("roomId == %@ AND createdAt >= %@", roomId, date)
                    .sorted(byKeyPath: "createdAt", ascending: true)
                
                let messages = realmMessages.map { message -> ChatEntity in
                    return ChatEntity(
                        chatId: message.chatId,
                        roomId: message.roomId,
                        content: message.content,
                        createdAt: PresentationMapper.formatDateToISO8601(message.createdAt),
                        updatedAt: PresentationMapper.formatDateToISO8601(message.updatedAt),
                        sender: message.senderId,
                        files: Array(message.files)
                    )
                }
                continuation.resume(returning: Array(messages))
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func deleteMessages(roomId: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let realm = try Realm(configuration: configuration)
                let messages = realm.objects(ChatRealmModel.self)
                    .filter("roomId == %@", roomId)
                
                try realm.write {
                    realm.delete(messages)
                }
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func getLastMessageDate(roomId: String) async throws -> Date? {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let realm = try Realm(configuration: configuration)
                let lastMessage = realm.objects(ChatRealmModel.self)
                    .filter("roomId == %@", roomId)
                    .sorted(byKeyPath: "createdAt", ascending: false)
                    .first
                
                continuation.resume(returning: lastMessage?.createdAt)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func updateUserId(oldUserId: String, newUserId: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let realm = try Realm(configuration: configuration)
                
                // ChatRealmModel의 senderId 업데이트
                let chatMessages = realm.objects(ChatRealmModel.self)
                try realm.write {
                    for message in chatMessages {
                        // 현재 로그인한 사용자의 메시지인 경우에만 업데이트
                        if message.senderId == oldUserId {
                            message.senderId = newUserId
                            print("✅ 메시지 senderId 업데이트: \(oldUserId) -> \(newUserId)")
                        }
                    }
                }
                
                // ChatRoomRealmModel의 participants 업데이트 (UserInfoRealmModel)
                let chatRooms = realm.objects(ChatRoomRealmModel.self)
                try realm.write {
                    for room in chatRooms {
                        for participant in room.participants {
                            if participant.userId == oldUserId {
                                participant.userId = newUserId
                                print("✅ 채팅방 participants 업데이트: \(oldUserId) -> \(newUserId)")
                            }
                        }
                    }
                }
                
                // ChatListRealmModel의 participants 업데이트 (String)
                let chatLists = realm.objects(ChatListRealmModel.self)
                try realm.write {
                    for chatList in chatLists {
                        if let index = chatList.participants.index(of: oldUserId) {
                            chatList.participants[index] = newUserId
                            print("✅ 채팅 목록 participants 업데이트: \(oldUserId) -> \(newUserId)")
                        }
                    }
                }
                
                continuation.resume()
            } catch {
                print("❌ userId 업데이트 실패: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            }
        }
    }
    
    func resetDatabase() async throws {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let realm = try Realm(configuration: configuration)
                try realm.write {
                    realm.deleteAll()
                }
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func isUserExists(userId: String) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let realm = try Realm(configuration: configuration)
                // participants에서 userId 확인
                let chatRooms = realm.objects(ChatRoomRealmModel.self)
                let chatLists = realm.objects(ChatListRealmModel.self)
                
                let userExistsInRooms = chatRooms.contains { room in
                    room.participants.contains(where: { $0.userId == userId })
                }
                
                let userExistsInLists = chatLists.contains { chatList in
                    chatList.participants.contains(userId)
                }
                
                continuation.resume(returning: userExistsInRooms || userExistsInLists)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func isUserInChatRoom(roomId: String, userId: String) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let realm = try Realm(configuration: configuration)
                if let chatList = realm.object(ofType: ChatListRealmModel.self, forPrimaryKey: roomId) {
                    let userExists = chatList.participants.contains(userId)
                    continuation.resume(returning: userExists)
                } else {
                    continuation.resume(returning: false)
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func getOpponentProfile(roomId: String, opponentId: String) async throws -> OpponentEntity? {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let realm = try Realm(configuration: configuration)
                if let chatList = realm.object(ofType: ChatListRealmModel.self, forPrimaryKey: roomId) {
                    // participants에서 opponentId와 일치하는 사용자 찾기 (String 리스트)
                    if chatList.participants.contains(opponentId) {
                        // 기본 정보로 OpponentEntity 생성 (실제 프로필 정보는 별도로 가져와야 함)
                        let opponentEntity = OpponentEntity(
                            userId: opponentId,
                            nick: "",
                            introduction: "",
                            profileImage: ""
                        )
                        continuation.resume(returning: opponentEntity)
                    } else {
                        continuation.resume(returning: nil)
                    }
                } else {
                    continuation.resume(returning: nil)
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
