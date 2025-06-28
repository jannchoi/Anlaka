import UIKit
import Combine
import SwiftUI

struct ChattingModel {
    var opponent_id: String?
    var roomId: String
    var messages: [ChatEntity] = []
    var isLoading: Bool = false
    var error: String? = nil
    var lastMessageDate: Date? = nil
    var isConnected: Bool = false
    var sendingMessageId: String? = nil  // 전송 중인 메시지 ID
    var tempMessage: ChatEntity? = nil   // 임시 메시지
    var messagesGroupedByDate: [(String, [ChatEntity])] = []  // 일반 프로퍼티로 변경
    
    // 시간순으로 정렬된 메시지 반환
    var sortedMessages: [ChatEntity] {
        var allMessages = messages
        if let temp = tempMessage {
            // tempMessage가 messages에 없는 경우에만 추가
            if !allMessages.contains(where: { $0.chatId == temp.chatId }) {
                allMessages.append(temp)
            }
        }
        return allMessages.sorted(by: { 
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
        socket = WebSocketManager(roomId: model.roomId)
        socket?.onMessage = { [weak self] message in
            self?.handleIncomingMessage(message)
        }
        socket?.onConnectionStatusChanged = { [weak self] isConnected in
            DispatchQueue.main.async {
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
            print("🔍 저장된 userID: \(userInfo.userid)")
            
            // opponent_id가 있는 경우 (새로운 채팅방 생성 또는 기존 채팅방 찾기)
            if let opponent_id = model.opponent_id {
                // 1. 채팅방 생성 또는 정보 가져오기
                let chatRoom = try await repository.getChatRoom(opponent_id: opponent_id)
                // roomId 업데이트
                model.roomId = chatRoom.roomId
            }
            
            // 2. 이전 user_id를 새로운 user_id로 업데이트
            do {
                try await databaseRepository.updateUserId(oldUserId: "68293ac68884d1a48e224692", newUserId: userInfo.userid)
            } catch {
                print("❌ user_id 업데이트 실패: \(error.localizedDescription)")
            }
            
            // 3. 로컬 DB에서 채팅 내역 조회 (업데이트 후)
            let localMessages = try await databaseRepository.getMessages(roomId: model.roomId)
            model.messages = localMessages
            print("📱 업데이트 후 메시지 senderId:", localMessages.map { $0.sender.userId })
            
            // 4. 마지막 메시지 날짜 가져오기
            if let lastDate = try await databaseRepository.getLastMessageDate(roomId: model.roomId) {
                // 5. 서버에서 최신 메시지 동기화
                let formattedDate = PresentationMapper.formatDateToISO8601(lastDate)
                let chatList = try await repository.getChatList(roomId: model.roomId, from: formattedDate)
                
                // 6. 새 메시지 저장 및 UI 업데이트
                try await databaseRepository.saveMessages(chatList.chats)
                
                // 중복되지 않은 새 메시지만 추가
                let newMessages = chatList.chats.filter { newMessage in
                    !model.messages.contains { $0.chatId == newMessage.chatId }
                }
                model.messages.append(contentsOf: newMessages)
                model.updateMessagesGroupedByDate()  // 메시지 그룹화 업데이트
            } else {
                // 첫 로드인 경우 전체 메시지 가져오기
                let chatList = try await repository.getChatList(roomId: model.roomId, from: nil)
                try await databaseRepository.saveMessages(chatList.chats)
                model.messages = chatList.chats
                model.updateMessagesGroupedByDate()  // 메시지 그룹화 업데이트
            }
            
            // 7. WebSocket 연결 - 여기서만 연결
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
            sender: UserInfoEntity(
                userId: userInfo.userid,  // 현재 로그인한 사용자의 ID 사용
                nick: userInfo.nick,
                introduction: userInfo.introduction ?? "",
                profileImage: userInfo.profileImage ?? ""
            ),
            files: []
        )
        
        // 임시 메시지 추가 및 그룹화 업데이트
        model.tempMessage = tempMessage
        model.updateMessagesGroupedByDate()
        
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
            
            // 3. 메시지 전송
            print("📝 메시지 전송 요청")
            let chatRequest = ChatRequestEntity(
                content: text,
                files: uploadedFiles
            )
            
            // Socket.IO를 통한 메시지 전송
            let messageData: [String: Any] = [
                "content": text,
                "files": uploadedFiles,
                "roomId": model.roomId
            ]
            
            socket?.emit("chat", with: [messageData]) { [weak self] in
                // 메시지 전송 완료 후 처리
                Task {
                    do {
                        // 서버에서 메시지 ID를 받아와서 저장
                        let message = try await self?.repository.sendMessage(
                            roomId: self?.model.roomId ?? "",
                            target: chatRequest
                        )
                        
                        if let message = message {
                            print("✅ 메시지 전송 성공:", message)
                            // DB 저장 및 UI 업데이트
                            if !(self?.model.messages.contains(where: { $0.chatId == message.chatId }) ?? false) {
                                // 서버에서 받은 메시지의 sender 정보를 현재 사용자 정보로 업데이트
                                let updatedMessage = ChatEntity(
                                    chatId: message.chatId,
                                    roomId: message.roomId,
                                    content: message.content,
                                    createdAt: message.createdAt,
                                    updatedAt: message.updatedAt,
                                    sender: UserInfoEntity(
                                        userId: userInfo.userid,  // 현재 로그인한 사용자의 ID 사용
                                        nick: userInfo.nick,
                                        introduction: userInfo.introduction ?? "",
                                        profileImage: userInfo.profileImage ?? ""
                                    ),
                                    files: message.files
                                )
                                
                                try await self?.databaseRepository.saveMessage(updatedMessage)
                                self?.model.messages.append(updatedMessage)
                                self?.model.updateMessagesGroupedByDate()  // 그룹화 업데이트
                            }
                        } else {
                            print("❌ 메시지 전송 실패: 응답이 없음")
                            self?.model.error = "메시지 전송에 실패했습니다."
                        }
                        
                        // 임시 메시지 제거 및 전송 완료 처리
                        self?.model.tempMessage = nil
                        self?.model.sendingMessageId = nil
                        self?.model.updateMessagesGroupedByDate()  // 임시 메시지 제거 후 그룹화 업데이트
                    } catch {
                        print("❌ 메시지 전송 실패: \(error.localizedDescription)")
                        self?.model.error = error.localizedDescription
                        // 임시 메시지 제거 및 전송 완료 처리
                        self?.model.tempMessage = nil
                        self?.model.sendingMessageId = nil
                        self?.model.updateMessagesGroupedByDate()  // 임시 메시지 제거 후 그룹화 업데이트
                    }
                }
            }
            
        } catch {
            print("❌ 메시지 전송 실패: \(error.localizedDescription)")
            model.error = error.localizedDescription
            // 임시 메시지 제거 및 전송 완료 처리
            model.tempMessage = nil
            model.sendingMessageId = nil
            model.updateMessagesGroupedByDate()  // 임시 메시지 제거 후 그룹화 업데이트
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
                // 이미 존재하는 메시지인지 확인
                if model.messages.contains(where: { $0.chatId == message.chatID }) {
                    return
                }
                
                let chatEntity = ChatEntity(
                    chatId: message.chatID,
                    roomId: message.roomID,
                    content: message.content,
                    createdAt: message.createdAt,
                    updatedAt: message.updatedAt,
                    sender: UserInfoEntity(
                        userId: message.sender.userID,
                        nick: message.sender.nick,
                        introduction: message.sender.introduction,
                        profileImage: message.sender.profileImage
                    ),
                    files: message.files
                )
                
                // DB 저장 및 UI 업데이트
                try await databaseRepository.saveMessage(chatEntity)
                model.messages.append(chatEntity)
                model.updateMessagesGroupedByDate()  // 메시지 그룹화 업데이트
            } catch {
                model.error = error.localizedDescription
            }
        }
    }
    
    deinit {
        socket?.disconnect()
    }
    
    
}   
