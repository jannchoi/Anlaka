import UIKit
import Combine
import SwiftUI

struct ChattingModel {
    var opponent_id: String?
    var opponentProfile: OtherProfileInfoEntity? = nil
    var roomId: String
    var messages: [ChatEntity] = []
    var isLoading: Bool = false
    var error: String? = nil
    var lastMessageDate: Date? = nil
    var isConnected: Bool = false
    var sendingMessageId: String? = nil  // 전송 중인 메시지 ID
    var messagesGroupedByDate: [(String, [ChatEntity])] = []  // 일반 프로퍼티로 변경
    var currentUserId: String? = nil  // 현재 로그인한 사용자의 ID
    
    // 시간순으로 정렬된 메시지 반환
    var sortedMessages: [ChatEntity] {
        // 중복 제거 (chatId 기준) - Dictionary 사용
        var uniqueMessagesDict: [String: ChatEntity] = [:]
        for message in messages {
            uniqueMessagesDict[message.chatId] = message
        }
        let uniqueMessages = Array(uniqueMessagesDict.values)
        
        return uniqueMessages.sorted(by: { 
            PresentationMapper.parseISO8601ToDate($0.createdAt) < PresentationMapper.parseISO8601ToDate($1.createdAt)
        })
    }
    
    // 메시지가 변경될 때 날짜별 그룹화 업데이트
    mutating func updateMessagesGroupedByDate() {
        var calendar = Calendar.current
        let koreaTimeZone = TimeZone(identifier: "Asia/Seoul")!
        calendar.timeZone = koreaTimeZone
        
        let grouped = Dictionary(grouping: sortedMessages) { message in
            let utcDate = PresentationMapper.parseISO8601ToDate(message.createdAt)
            return calendar.startOfDay(for: utcDate)
        }
        messagesGroupedByDate = grouped.sorted { $0.key < $1.key }
            .map { (date, messages) -> (String, [ChatEntity]) in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy년 MM월 dd일"
                formatter.locale = Locale(identifier: "ko_KR")
                formatter.timeZone = koreaTimeZone
                return (formatter.string(from: date), messages)
            }
    }
}

enum ChattingIntent {
    case initialLoad
    case sendMessage(text: String, files: [GalleryImage])
    case loadMoreMessages
    case reconnectSocket
    case disconnectSocket
}

@MainActor
final class ChattingContainer: ObservableObject {
    @Published var model: ChattingModel
    private let repository: NetworkRepository
    private let databaseRepository: DatabaseRepository
    private var socket: WebSocketManager?
    private var cancellables = Set<AnyCancellable>()
    
    init(repository: NetworkRepository, databaseRepository: DatabaseRepository, opponent_id: String) {
        self.repository = repository
        self.databaseRepository = databaseRepository
        self.model = ChattingModel(opponent_id: opponent_id, roomId: opponent_id)
        setupSocket()
    }
    
    init(repository: NetworkRepository, databaseRepository: DatabaseRepository, roomId: String) {
        self.repository = repository
        self.databaseRepository = databaseRepository
        self.model = ChattingModel(opponent_id: nil, roomId: roomId)
        setupSocket()
    }
    
    private func setupSocket() {
        print("🔧 WebSocketManager 생성: roomId = \(model.roomId)")
        socket = WebSocketManager(roomId: model.roomId)
        socket?.onMessage = { [weak self] message in
            self?.handleIncomingMessage(message)
        }
        socket?.onConnectionStatusChanged = { [weak self] isConnected in
            DispatchQueue.main.async {
                print("🔌 WebSocket 연결 상태 변경: \(isConnected)")
                self?.model.isConnected = isConnected
            }
        }
        // 초기화 시에는 연결하지 않음
    }
    
    func handle(_ intent: ChattingIntent) {
        switch intent {
        case .initialLoad:
            Task {
                await loadInitialMessages()
            }
        case .sendMessage(let text, let files):
            Task {
                await sendMessage(text: text, files: files)
            }
        case .loadMoreMessages:
            Task {
                await loadMoreMessages()
            }
        case .reconnectSocket:
            socket?.connect()
        case .disconnectSocket:
            socket?.disconnect()
        }
    }
    
    private func loadInitialMessages() async {
        model.isLoading = true
        do {
            // 현재 로그인한 사용자 정보 가져오기
            guard let userInfo = UserDefaultsManager.shared.getObject(forKey: .profileData, as: MyProfileInfoEntity.self) else {
                model.error = "사용자 정보를 찾을 수 없습니다."
                model.isLoading = false
                return
            }
            model.currentUserId = userInfo.userid
            
            // opponent_id가 있는 경우 (새로운 채팅방 생성 또는 기존 채팅방 찾기)
            if let opponent_id = model.opponent_id {
                // 1. 채팅방 생성 또는 정보 가져오기
                let chatRoom = try await repository.getChatRoom(opponent_id: opponent_id)
                // roomId 업데이트
                model.roomId = chatRoom.roomId
                
                // WebSocketManager를 새로운 roomId로 다시 생성
                setupSocket()
                
                // 2. 상대방 프로필 정보 가져오기
                let opponentProfile = try await repository.getOtherProfileInfo(userId: opponent_id)
                    model.opponentProfile = opponentProfile
                    print("👤 상대방 프로필 정보 로드 완료: \(opponentProfile)")
            }
            
            // 3. 현재 사용자가 해당 채팅방에 존재하는지 확인
            let userInChatRoom = try await databaseRepository.isUserInChatRoom(roomId: model.roomId, userId: userInfo.userid)
            
            if !userInChatRoom {
                // 4. 현재 사용자가 채팅방에 없는 경우 채팅방 삭제
                try await databaseRepository.deleteChatRoom(roomId: model.roomId)
                
                // 5. 서버에서 전체 채팅 내역 가져오기
                let chatList = try await repository.getChatList(roomId: model.roomId, from: nil)
                try await databaseRepository.saveMessages(chatList.chats)
                model.messages = chatList.chats
            } else {
                // 6. 기존 사용자인 경우 로컬 DB에서 채팅 내역 조회
                let localMessages = try await databaseRepository.getMessages(roomId: model.roomId)
                model.messages = localMessages
                
                // 7. 마지막 메시지 날짜 가져오기
                if let lastDate = try await databaseRepository.getLastMessageDate(roomId: model.roomId) {
                    // 8. 서버에서 최신 메시지 동기화
                    let formattedDate = PresentationMapper.formatDateToISO8601(lastDate)
                    let chatList = try await repository.getChatList(roomId: model.roomId, from: formattedDate)
                    
                    // 9. 새 메시지 저장 및 UI 업데이트
                    try await databaseRepository.saveMessages(chatList.chats)
                    
                    // 중복되지 않은 새 메시지만 추가
                    let newMessages = chatList.chats.filter { newMessage in
                        !model.messages.contains { $0.chatId == newMessage.chatId }
                    }
                    model.messages.append(contentsOf: newMessages)
                }
            }
            
            // 10. 메시지 그룹화 업데이트
            model.updateMessagesGroupedByDate()
            
            // 11. WebSocket 연결
            print("🔌 WebSocket 연결 시도: roomId = \(model.roomId)")
            socket?.connect()
            
        } catch {
            model.error = error.localizedDescription
        }
        model.isLoading = false
    }

    private func sendMessage(text: String, files: [GalleryImage]) async {
        // 임시 메시지 ID 생성
        let tempMessageId = "temp_\(UUID().uuidString)"
        model.sendingMessageId = tempMessageId
        
        // 현재 사용자 정보 가져오기
        guard let userInfo = UserDefaultsManager.shared.getObject(forKey: .profileData, as: MyProfileInfoEntity.self) else {
            model.error = "사용자 정보를 찾을 수 없습니다."
            return
        }
        
        // 임시 메시지 생성
        let tempMessage = ChatEntity(
            chatId: tempMessageId,
            roomId: model.roomId,
            content: text,
            createdAt: PresentationMapper.formatDateToISO8601(Date()),
            updatedAt: PresentationMapper.formatDateToISO8601(Date()),
            sender: userInfo.userid,
            files: []
        )
        
        // 임시 메시지를 즉시 UI에 추가
        model.messages.append(tempMessage)
        model.updateMessagesGroupedByDate()
        print("📝 임시 메시지 추가: \(tempMessageId)")
        
        do {
            // 1. GalleryImage를 ChatFile로 변환
            let chatFiles = files.map { galleryImage in
                let fileExtension = galleryImage.fileName.split(separator: ".").last?.lowercased() ?? "jpg"
                print("📝 파일 변환 중: \(galleryImage.fileName), 확장자: \(fileExtension)")
                
                // 파일 확장자에 따른 데이터 변환 및 MIME 타입 설정
                let (data, mimeType) = convertImageToData(galleryImage.image, fileExtension: fileExtension)
                print("📝 변환된 데이터 크기: \(data.count) bytes, MIME 타입: \(mimeType)")
                
                return ChatFile(
                    data: data,
                    fileName: galleryImage.fileName,
                    mimeType: mimeType,
                    fileExtension: fileExtension
                )
            }
            
            // 2. 파일 업로드
            var uploadedFiles: [String] = []
            if !chatFiles.isEmpty {
                print("📝 파일 업로드 시작")
                let chatFile = try await repository.uploadFiles(roomId: model.roomId, files: chatFiles)
                uploadedFiles = chatFile.files
                print("✅ 파일 업로드 성공 - 업로드된 파일 URL: \(uploadedFiles)")
            }
            
            // 3. Socket.IO를 통한 메시지 전송 (업로드된 파일 URL을 그대로 전송)
            let messageData: [String: Any] = [
                "content": text,
                "files": uploadedFiles,  // 서버에서 받은 파일 URL 그대로 사용
                "roomId": model.roomId
            ]
            
            print("📤 WebSocket으로 전송할 메시지 데이터: \(messageData)")
            
            socket?.emit("chat", with: [messageData]) { [weak self] in
                // 메시지 전송 완료 후 처리
                Task {
                    do {
                        // Socket.IO 전송 완료 후 HTTP로 실제 메시지 ID 받아오기
                        let chatRequest = ChatRequestEntity(
                            content: text,
                            files: uploadedFiles  // 업로드된 파일 URL 그대로 사용
                        )
                        
                        let message = try await self?.repository.sendMessage(
                            roomId: self?.model.roomId ?? "",
                            target: chatRequest
                        )
                        
                        if let message = message {
                            // 임시 메시지를 실제 메시지로 교체
                            if let tempIndex = self?.model.messages.firstIndex(where: { $0.chatId == tempMessageId }) {
                                self?.model.messages[tempIndex] = message
                                print("🔄 임시 메시지를 실제 메시지로 교체: \(message.chatId)")
                            }
                            
                            // DB 저장
                            try await self?.databaseRepository.saveMessage(message)
                            
                            // 전송 상태 업데이트
                            self?.model.sendingMessageId = nil
                            self?.model.updateMessagesGroupedByDate()
                            print("✅ 메시지 전송 및 저장 완료: \(message.chatId)")
                        } else {
                            print("❌ 메시지 전송 실패: 응답이 없음")
                            self?.model.error = "메시지 전송에 실패했습니다."
                            // 에러 발생 시 임시 메시지 제거
                            self?.model.messages.removeAll { $0.chatId == tempMessageId }
                            self?.model.sendingMessageId = nil
                            self?.model.updateMessagesGroupedByDate()
                        }
                    } catch {
                        print("❌ 메시지 전송 실패: \(error.localizedDescription)")
                        self?.model.error = error.localizedDescription
                        // 에러 발생 시 임시 메시지 제거
                        self?.model.messages.removeAll { $0.chatId == tempMessageId }
                        self?.model.sendingMessageId = nil
                        self?.model.updateMessagesGroupedByDate()
                    }
                }
            }
            
        } catch {
            print("❌ 메시지 전송 실패: \(error.localizedDescription)")
            model.error = error.localizedDescription
            // 에러 발생 시 임시 메시지 제거
            model.messages.removeAll { $0.chatId == tempMessageId }
            model.sendingMessageId = nil
            model.updateMessagesGroupedByDate()
        }
    }
    
    // 이미지를 적절한 형식의 데이터로 변환하는 헬퍼 메서드
    private func convertImageToData(_ image: UIImage, fileExtension: String) -> (Data, String) {
        switch fileExtension {
        case "jpg", "jpeg":
            return (image.jpegData(compressionQuality: 0.8) ?? Data(), "image/jpeg")
        case "png":
            return (image.pngData() ?? Data(), "image/png")
        case "gif":
            // GIF는 현재 UIImage에서 직접 변환할 수 없으므로 JPEG로 대체
            return (image.jpegData(compressionQuality: 0.8) ?? Data(), "image/jpeg")
        case "pdf":
            // PDF는 현재 UIImage에서 직접 변환할 수 없으므로 JPEG로 대체
            return (image.jpegData(compressionQuality: 0.8) ?? Data(), "image/jpeg")
        default:
            // 기본값으로 JPEG 사용
            return (image.jpegData(compressionQuality: 0.8) ?? Data(), "image/jpeg")
        }
    }
    
    private func loadMoreMessages() async {
        guard let firstMessage = model.messages.first else { return }
        
        do {
            let fromDate = firstMessage.createdAt
            
            let chatList = try await repository.getChatList(
                roomId: model.roomId,
                from: fromDate
            )
            
            // DB 저장 및 UI 업데이트
            try await databaseRepository.saveMessages(chatList.chats)
            model.messages.insert(contentsOf: chatList.chats, at: 0)
        } catch {
            model.error = error.localizedDescription
        }
    }
    
    private func handleIncomingMessage(_ message: ChatMessageEntity) {
        Task {
            do {
                // 이미 존재하는 메시지인지 확인 (UI 레벨)
                if model.messages.contains(where: { $0.chatId == message.chatID }) {
                    print("⚠️ 이미 UI에 존재하는 메시지 무시: \(message.chatID)")
                    return
                }
                
                // DB에서도 중복 체크
                let existingMessages = try await databaseRepository.getMessages(roomId: message.roomID)
                if existingMessages.contains(where: { $0.chatId == message.chatID }) {
                    print("⚠️ 이미 DB에 존재하는 메시지 무시: \(message.chatID)")
                    return
                }
                
                let chatEntity = ChatEntity(
                    chatId: message.chatID,
                    roomId: message.roomID,
                    content: message.content,
                    createdAt: message.createdAt,
                    updatedAt: message.updatedAt,
                    sender: message.sender,
                    files: message.files
                )
                
                // DB 저장 및 UI 업데이트
                try await databaseRepository.saveMessage(chatEntity)
                model.messages.append(chatEntity)
                model.updateMessagesGroupedByDate()
                print("✅ 새 메시지 저장 완료: \(message.chatID)")
            } catch {
                print("❌ 메시지 저장 실패: \(error.localizedDescription)")
                // 에러가 발생해도 채팅은 계속 진행 (model.error 설정하지 않음)
            }
        }
    }
    
    deinit {
        socket?.disconnect()
    }
    
    
}   
