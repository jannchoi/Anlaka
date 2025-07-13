import Foundation
import RealmSwift

// 채팅방 모델
class ChatRoomRealmModel: Object {
    @Persisted(primaryKey: true) var roomId: String
    @Persisted var lastChat: ChatRealmModel?
    @Persisted var updatedAt: Date
    @Persisted var participants: List<UserInfoRealmModel>
    
    convenience init(roomId: String, lastChat: ChatRealmModel?, createdAt: Date, updatedAt: Date, participants: [UserInfoRealmModel]) {
        self.init()
        self.roomId = roomId
        self.lastChat = lastChat
        self.updatedAt = updatedAt
        self.participants.append(objectsIn: participants)
    }
}

// 사용자 정보 모델
class UserInfoRealmModel: Object {
    @Persisted var userId: String
    @Persisted var nick: String
    @Persisted var introduction: String?
    @Persisted var profileImage: String?
    
    convenience init(userId: String, nick: String, introduction: String?, profileImage: String?) {
        self.init()
        self.userId = userId
        self.nick = nick
        self.introduction = introduction
        self.profileImage = profileImage
    }
}

// 채팅 목록 모델
class ChatListRealmModel: Object {
    @Persisted(primaryKey: true) var roomId: String
    @Persisted var chats: List<ChatRealmModel>
    @Persisted var participants: List<String>
    
    convenience init(roomId: String, chats: [ChatRealmModel], participants: [String]) {
        self.init()
        self.roomId = roomId
        self.chats.append(objectsIn: chats)
        self.participants.append(objectsIn: participants)
    }
}

// 채팅 메시지 모델
class ChatRealmModel: Object {
    @Persisted(primaryKey: true) var chatId: String
    @Persisted var roomId: String
    @Persisted var content: String
    @Persisted var createdAt: Date
    @Persisted var updatedAt: Date
    @Persisted var senderId: String
    @Persisted var files: List<String>
    
    convenience init(chatId: String, content: String, createdAt: Date, updatedAt: Date, senderId: String, files: [String], roomId: String) {
        self.init()
        self.chatId = chatId
        self.roomId = roomId
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.senderId = senderId
        self.files.append(objectsIn: files)
    }
} 
