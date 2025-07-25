import Foundation

/// 알림 body를 사용한 임시 마지막 메시지 관리 매니저
final class TemporaryLastMessageManager: ObservableObject {
    static let shared = TemporaryLastMessageManager()
    
    @Published private(set) var temporaryMessages: [String: TemporaryLastMessage] = [:]
    
    private let userDefaults: UserDefaults? = {
        let suiteName = "group.com.jann.Anlaka"
        guard !suiteName.isEmpty else {
            print("❌ UserDefaults suiteName이 빈 문자열입니다")
            return nil
        }
        return UserDefaults(suiteName: suiteName)
    }()
    private let temporaryMessagesKey = "TemporaryLastMessages"
    
    // 디바운싱을 위한 타이머
    private var debounceTimers: [String: Timer] = [:]
    private let debounceInterval: TimeInterval = 2.0 // 2초 디바운싱
    
    private init() {
        migrateFromStandardUserDefaults()
        loadTemporaryMessages()
    }
    
    /// 임시 마지막 메시지 구조체
    struct TemporaryLastMessage: Equatable {
        let content: String
        let senderId: String
        let senderNick: String
        let timestamp: Date
        let hasFiles: Bool
        
        init(content: String, senderId: String, senderNick: String, timestamp: Date, hasFiles: Bool = false) {
            self.content = content
            self.senderId = senderId
            self.senderNick = senderNick
            self.timestamp = timestamp
            self.hasFiles = hasFiles
        }
        
        static func == (lhs: TemporaryLastMessage, rhs: TemporaryLastMessage) -> Bool {
            return lhs.content == rhs.content &&
                   lhs.senderId == rhs.senderId &&
                   lhs.senderNick == rhs.senderNick &&
                   lhs.timestamp == rhs.timestamp &&
                   lhs.hasFiles == rhs.hasFiles
        }
    }
    
    /// 알림 body로 임시 마지막 메시지 설정 (디바운싱 적용)
    func setTemporaryLastMessage(roomId: String, content: String, senderId: String, senderNick: String, hasFiles: Bool = false) {
        // 기존 타이머 취소
        debounceTimers[roomId]?.invalidate()
        
        // 즉시 UI 업데이트
        let tempMessage = TemporaryLastMessage(
            content: content,
            senderId: senderId,
            senderNick: senderNick,
            timestamp: Date(),
            hasFiles: hasFiles
        )
        
        temporaryMessages[roomId] = tempMessage
        saveTemporaryMessages()
        
        // @Published 속성이 변경되었음을 알림
        objectWillChange.send()
        
        // 디바운싱 타이머 설정 (서버 동기화는 나중에)
        debounceTimers[roomId] = Timer.scheduledTimer(withTimeInterval: debounceInterval, repeats: false) { _ in
            // 여기서 서버 동기화 로직을 추가할 수 있음
        }
    }
    
    /// 특정 채팅방의 임시 마지막 메시지 조회
    func getTemporaryLastMessage(for roomId: String) -> TemporaryLastMessage? {
        return temporaryMessages[roomId]
    }
    
    /// 특정 채팅방의 임시 마지막 메시지 제거 (채팅방 진입 시)
    func removeTemporaryLastMessage(for roomId: String) {
        temporaryMessages.removeValue(forKey: roomId)
        saveTemporaryMessages()
        objectWillChange.send()

    }
    
    /// 모든 임시 마지막 메시지 제거
    func removeAllTemporaryLastMessages() {
        temporaryMessages.removeAll()
        saveTemporaryMessages()
        objectWillChange.send()

    }
    
    /// 모든 임시 마지막 메시지 제거 (clearAllTemporaryMessages와 동일)
    func clearAllTemporaryMessages() {
        removeAllTemporaryLastMessages()
    }
    
    /// 임시 마지막 메시지의 상대적 시간 포맷팅
    func formatTemporaryMessageTime(for roomId: String) -> String {
        guard let tempMessage = temporaryMessages[roomId] else { return "" }
        
        let now = Date()
        let timeInterval = now.timeIntervalSince(tempMessage.timestamp)
        
        // 24시간 이내: "HH:mm" 형식
        if timeInterval < 86400 {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
            return formatter.string(from: tempMessage.timestamp)
        }
        // 24시간 초과: "M월 d일" 형식
        else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M월 d일"
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
            return formatter.string(from: tempMessage.timestamp)
        }
    }
    
    // MARK: - Private Methods
    
    private func saveTemporaryMessages() {
        if let data = try? JSONEncoder().encode(temporaryMessages) {
            userDefaults?.set(data, forKey: temporaryMessagesKey)
        }
    }
    
    private func loadTemporaryMessages() {
        if let data = userDefaults?.data(forKey: temporaryMessagesKey),
           let messages = try? JSONDecoder().decode([String: TemporaryLastMessage].self, from: data) {
            temporaryMessages = messages
        }
    }
    
    /// 기존 UserDefaults에서 App Groups로 데이터 마이그레이션
    private func migrateFromStandardUserDefaults() {
        let standardDefaults = UserDefaults.standard
        let oldData = standardDefaults.data(forKey: temporaryMessagesKey)
        
        if let oldData = oldData,
           let oldMessages = try? JSONDecoder().decode([String: TemporaryLastMessage].self, from: oldData),
           !oldMessages.isEmpty {
            temporaryMessages = oldMessages
            saveTemporaryMessages()
            
            // 마이그레이션 후 기존 데이터 삭제
            standardDefaults.removeObject(forKey: temporaryMessagesKey)
        }
    }
}

// MARK: - TemporaryLastMessage Codable
extension TemporaryLastMessageManager.TemporaryLastMessage: Codable {
    enum CodingKeys: String, CodingKey {
        case content, senderId, senderNick, timestamp, hasFiles
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        content = try container.decode(String.self, forKey: .content)
        senderId = try container.decode(String.self, forKey: .senderId)
        senderNick = try container.decode(String.self, forKey: .senderNick)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        hasFiles = try container.decode(Bool.self, forKey: .hasFiles)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(content, forKey: .content)
        try container.encode(senderId, forKey: .senderId)
        try container.encode(senderNick, forKey: .senderNick)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(hasFiles, forKey: .hasFiles)
    }
} 
