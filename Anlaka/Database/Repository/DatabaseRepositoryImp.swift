import Foundation
import RealmSwift

final class DatabaseRepositoryImp: DatabaseRepository {
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
                            senderId: chat.sender.userId,
                            files: chat.files,
                            roomId: room.roomId
                        )
                    }
                    
                    let participants = room.participants.map { participant -> UserInfoRealmModel in
                        UserInfoRealmModel(
                            userId: participant.userId,
                            nick: participant.nick,
                            introduction: participant.introduction ?? "",
                            profileImage: participant.profileImage ?? ""
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
                            sender: UserInfoEntity(
                                userId: chat.senderId,
                                nick: "",
                                introduction: "",
                                profileImage: ""
                            ),
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
                            senderId: chat.sender.userId,
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
                let realmMessages = messages.map { message -> ChatRealmModel in
                    ChatRealmModel(
                        chatId: message.chatId,
                        content: message.content,
                        createdAt: PresentationMapper.parseISO8601ToDate(message.createdAt),
                        updatedAt: PresentationMapper.parseISO8601ToDate(message.updatedAt),
                        senderId: message.sender.userId,
                        files: message.files,
                        roomId: message.roomId
                    )
                }
                
                try realm.write {
                    // 중복 체크 후 저장
                    for realmMessage in realmMessages {
                        if realm.object(ofType: ChatRealmModel.self, forPrimaryKey: realmMessage.chatId) == nil {
                            realm.add(realmMessage, update: .modified)
                        }
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
                    senderId: message.sender.userId,
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
                    
                    // 새로운 참여자 추가
                    let senderInfo = UserInfoRealmModel(
                        userId: message.sender.userId,
                        nick: message.sender.nick,
                        introduction: message.sender.introduction,
                        profileImage: message.sender.profileImage
                    )
                    
                    if !chatList.participants.contains(where: { $0.userId == senderInfo.userId }) {
                        chatList.participants.append(senderInfo)
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
                
                // 현재 로그인한 사용자 정보 가져오기
                guard let userInfo = UserDefaultsManager.shared.getObject(forKey: .profileData, as: MyProfileInfoEntity.self) else {
                    continuation.resume(throwing: NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "사용자 정보를 찾을 수 없습니다."]))
                    return
                }
                
                let messages = chatList.chats.sorted(by: { $0.createdAt < $1.createdAt }).map { message -> ChatEntity in
                    // senderId를 통해 participant 정보 찾기
                    let sender = chatList.participants.first(where: { $0.userId == message.senderId })
                    
                    return ChatEntity(
                        chatId: message.chatId,
                        roomId: roomId,
                        content: message.content,
                        createdAt: PresentationMapper.formatDateToISO8601(message.createdAt),
                        updatedAt: PresentationMapper.formatDateToISO8601(message.updatedAt),
                        sender: UserInfoEntity(
                            userId: message.senderId,
                            nick: sender?.nick ?? "",
                            introduction: sender?.introduction ?? "",
                            profileImage: sender?.profileImage ?? ""
                        ),
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
                
                // 현재 로그인한 사용자 정보 가져오기
                guard let userInfo = UserDefaultsManager.shared.getObject(forKey: .profileData, as: MyProfileInfoEntity.self) else {
                    continuation.resume(throwing: NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "사용자 정보를 찾을 수 없습니다."]))
                    return
                }
                
                let messages = realmMessages.map { message -> ChatEntity in
                    let sender = realm.object(ofType: UserInfoRealmModel.self, forPrimaryKey: message.senderId)
                    return ChatEntity(
                        chatId: message.chatId,
                        roomId: message.roomId,
                        content: message.content,
                        createdAt: PresentationMapper.formatDateToISO8601(message.createdAt),
                        updatedAt: PresentationMapper.formatDateToISO8601(message.updatedAt),
                        sender: UserInfoEntity(
                            userId: message.senderId,
                            nick: sender?.nick ?? "",
                            introduction: sender?.introduction ?? "",
                            profileImage: sender?.profileImage ?? ""
                        ),
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
                
                // UserInfoRealmModel의 userId 업데이트
                let userInfos = realm.objects(UserInfoRealmModel.self)
                try realm.write {
                    for userInfo in userInfos {
                        if userInfo.userId == oldUserId {
                            userInfo.userId = newUserId
                            print("✅ 사용자 정보 userId 업데이트: \(oldUserId) -> \(newUserId)")
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
                let userExists = realm.objects(UserInfoRealmModel.self)
                    .filter("userId == %@", userId)
                    .first != nil
                continuation.resume(returning: userExists)
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
                    let userExists = chatList.participants.contains(where: { $0.userId == userId })
                    continuation.resume(returning: userExists)
                } else {
                    continuation.resume(returning: false)
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
} 
