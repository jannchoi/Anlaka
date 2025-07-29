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
    
    // 재연결 관련 상태 추가
    var isReconnecting: Bool = false
    var reconnectAttempts: Int = 0
    
    // 파일 검증 관련 상태
    var invalidFileIndices: Set<Int> = []
    var invalidFileReasons: [Int: String] = [:]
    
    // CustomToastView 관련 상태
    var toast: FancyToast? = nil
    
    // newMessageButton 흔들림 관련 상태
    var shouldShakeNewMessageButton: Bool = false
    
    // 페이지네이션 관련 상태 (New)
    var isLoadingMoreMessages: Bool = false  // 이전 메시지 로딩 중
    var hasMoreMessages: Bool = true  // 더 로드할 메시지가 있는지
    var oldestLoadedDate: Date? = nil  // 현재 로드된 가장 오래된 메시지 날짜
    var isInitialLoadComplete: Bool = false  // 초기 로드 완료 여부
    
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
    case sendMessage(text: String, files: [SelectedFile])
    case validateFiles([SelectedFile])
    case loadMoreMessages
    case loadPreviousMessages  // 이전 메시지 로드 (New)
    case reconnectSocket
    case disconnectSocket
    case setError(String?)  // 에러 설정을 위한 새로운 Intent 추가
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
        setupAppLifecycleObserver()
    }
    
    init(repository: NetworkRepository, databaseRepository: DatabaseRepository, roomId: String) {
        self.repository = repository
        self.databaseRepository = databaseRepository
        self.model = ChattingModel(opponent_id: nil, roomId: roomId)
        setupSocket()
        setupAppLifecycleObserver()
    }
    
    private func setupSocket() {
        print(" WebSocketManager 생성: roomId = \(model.roomId)")
        socket = WebSocketManager(roomId: model.roomId)
        socket?.onMessage = { [weak self] message in
            self?.handleIncomingMessage(message)
        }
        socket?.onConnectionStatusChanged = { [weak self] isConnected in
            DispatchQueue.main.async {
                print(" WebSocket 연결 상태 변경: \(isConnected)")
                self?.model.isConnected = isConnected
                
                // 연결이 끊어진 경우 재연결 시도
                if !isConnected {
                    self?.attemptReconnect()
                } else {
                    // 연결이 성공한 경우 재연결 상태 초기화
                    self?.model.isReconnecting = false
                    self?.model.reconnectAttempts = 0
                }
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
        case .validateFiles(let files):
            validateFiles(files)
        case .loadMoreMessages:
            Task {
                await loadMoreMessages()
            }
        case .loadPreviousMessages:
            Task {
                await loadPreviousMessages()
            }
        case .reconnectSocket:
            socket?.connect()
        case .disconnectSocket:
            socket?.disconnect()
        case .setError(let error):
            model.error = error
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
                    print(" 상대방 프로필 정보 로드 완료: \(opponentProfile)")
            } else {
                // roomId로 초기화된 경우, 채팅방 정보를 가져와서 상대방 프로필 정보 찾기
                // 1. 채팅방 정보 가져오기 (서버에서)
                let chatRooms = try await repository.getChatRooms()
                if let chatRoom = chatRooms.rooms.first(where: { $0.roomId == model.roomId }) {
                    // 2. participants에서 상대방 찾기
                    if let opponent = chatRoom.participants.first(where: { $0.userId != userInfo.userid }) {
                        // 3. opponent_id 설정
                        model.opponent_id = opponent.userId
                        print(" opponent_id 설정: \(opponent.userId)")
                        
                        // 4. 상대방 프로필 정보 가져오기
                        let opponentProfile = try await repository.getOtherProfileInfo(userId: opponent.userId)
                        model.opponentProfile = opponentProfile
                        print(" 상대방 프로필 정보 로드 완료 (roomId): \(opponentProfile)")
                    }
                }
            }
            
            // 3. 현재 사용자가 해당 채팅방에 존재하는지 확인
            let userInChatRoom = try await databaseRepository.isUserInChatRoom(roomId: model.roomId, userId: userInfo.userid)
            
            if !userInChatRoom {
                // 4. 현재 사용자가 채팅방에 없는 경우(이 기기를 사용하던 사람이 아니므로 db에 없음) 
                // 서버에서 최근 30일 채팅 내역만 가져와서 DB 초기화
                print("🆕 새 사용자: 서버에서 최근 30일 채팅 내역 로드")
                
                // DB에서 기존 채팅방 삭제
                try await databaseRepository.deleteChatRoom(roomId: model.roomId)
                
                // 서버에서 최근 30일 채팅 내역 가져오기 (from 파라미터 없이)
                let chatList = try await repository.getChatList(roomId: model.roomId, from: nil)
                
                // DB에 저장
                try await databaseRepository.saveMessages(chatList.chats)
                model.messages = chatList.chats
                
                // 가장 오래된 메시지 날짜 설정
                if let oldestMessage = chatList.chats.min(by: { 
                    PresentationMapper.parseISO8601ToDate($0.createdAt) < PresentationMapper.parseISO8601ToDate($1.createdAt) 
                }) {
                    model.oldestLoadedDate = PresentationMapper.parseISO8601ToDate(oldestMessage.createdAt)
                }
                
                // 더 오래된 메시지가 있는지 확인 (서버에서 한 번 더 요청해서 확인)
                if !chatList.chats.isEmpty {
                    let oldestDate = PresentationMapper.parseISO8601ToDate(chatList.chats.first!.createdAt)
                    let olderChatList = try await repository.getChatList(roomId: model.roomId, from: PresentationMapper.formatDateToISO8601(oldestDate))
                    model.hasMoreMessages = !olderChatList.chats.isEmpty
                    
                    if !olderChatList.chats.isEmpty {
                        print("📄 서버에 더 많은 메시지가 있습니다 (초기 로드 확인: \(olderChatList.chats.count)개)")
                    } else {
                        print("📭 서버에서 더 이상 메시지가 없습니다 (초기 로드 확인)")
                    }
                } else {
                    model.hasMoreMessages = false
                    print("📭 서버에서 메시지가 없습니다 (초기 로드)")
                }
                
            } else {
                // 5. 기존 사용자인 경우 로컬 DB에서 최근 30일 채팅 내역 조회
                print("👤 기존 사용자: 로컬 DB에서 최근 30일 채팅 내역 로드")
                
                // 30일 전 날짜 계산
                let calendar = Calendar.current
                let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
                
                // 로컬 DB에서 최근 30일 메시지 조회
                let localMessages = try await databaseRepository.getMessagesInDateRange(
                    roomId: model.roomId, 
                    from: thirtyDaysAgo, 
                    to: Date()
                )
                model.messages = localMessages
                
                // 가장 오래된 메시지 날짜 설정
                if let oldestMessage = localMessages.min(by: { 
                    PresentationMapper.parseISO8601ToDate($0.createdAt) < PresentationMapper.parseISO8601ToDate($1.createdAt) 
                }) {
                    model.oldestLoadedDate = PresentationMapper.parseISO8601ToDate(oldestMessage.createdAt)
                }
                
                // 더 오래된 메시지가 있는지 확인
                let totalMessageCount = try await databaseRepository.getMessagesCount(roomId: model.roomId)
                model.hasMoreMessages = totalMessageCount > localMessages.count
                
                // 6. 마지막 메시지 날짜 가져오기
                if let lastDate = try await databaseRepository.getLastMessageDate(roomId: model.roomId) {
                    // 7. 서버에서 최신 메시지 동기화
                    let formattedDate = PresentationMapper.formatDateToISO8601(lastDate)
                    let chatList = try await repository.getChatList(roomId: model.roomId, from: formattedDate)
                    
                    // 8. 새 메시지 저장 및 UI 업데이트
                    try await databaseRepository.saveMessages(chatList.chats)
                    
                    // 중복되지 않은 새 메시지만 추가
                    let newMessages = chatList.chats.filter { newMessage in
                        !model.messages.contains { $0.chatId == newMessage.chatId }
                    }
                    model.messages.append(contentsOf: newMessages)
                }
            }
            
            // 9. 메시지 그룹화 업데이트
            model.updateMessagesGroupedByDate()
            
            // 10. 초기 로드 완료 표시
            model.isInitialLoadComplete = true
            
            // 11. WebSocket 연결
            print(" WebSocket 연결 시도: roomId = \(model.roomId)")
            socket?.connect()
            
        } catch {
            model.error = error.localizedDescription
        }
        model.isLoading = false
    }

    private func sendMessage(text: String, files: [SelectedFile]) async {
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
        model.updateMessagesGroupedByDate()  // 임시 메시지도 UI에 표시되어야 함
        
        do {
            // 1. SelectedFile을 FileData로 변환
            let fileDataArray = files.compactMap { selectedFile in
                selectedFile.toFileData()
            }
            
            // 2. 파일 검증
            let validatedFiles = FileManageHelper.shared.validateFiles(fileDataArray, uploadType: FileUploadType.chat)
            // 유효한 파일이 없고 원본 파일이 있었다면 에러 처리
            if validatedFiles.isEmpty && !files.isEmpty {
                model.error = "선택된 파일 중 유효하지 않은 파일이 있습니다."
                model.messages.removeAll { $0.chatId == tempMessageId }
                model.sendingMessageId = nil
                model.updateMessagesGroupedByDate()
                return
            }
            
            // 유효한 파일이 일부만 있는 경우 로그 출력
            if validatedFiles.count < files.count {
                print("⚠️ 일부 파일이 검증을 통과하지 못했습니다.")
                print("   - 원본 파일 개수: \(files.count)")
                print("   - 유효한 파일 개수: \(validatedFiles.count)")
            }
            
            // 3. 파일 업로드
            var uploadedFiles: [String] = []
            if !validatedFiles.isEmpty {

                let chatFile = try await repository.uploadFiles(roomId: model.roomId, files: validatedFiles)
                uploadedFiles = chatFile
                print(" 파일 업로드 성공 - 업로드된 파일 URL: \(uploadedFiles)")
            }
            
            // 4. HTTP 서버로 메시지 전송
            let chatRequest = ChatRequestEntity(
                content: text,
                files: uploadedFiles  // 업로드된 파일 URL 그대로 사용
            )
            
            
            let message = try await repository.sendMessage(
                roomId: model.roomId,
                target: chatRequest
            )
            
            // 임시 메시지를 실제 메시지로 교체
            if let tempIndex = model.messages.firstIndex(where: { $0.chatId == tempMessageId }) {
                model.messages.remove(at: tempIndex)  // 임시 메시지 제거
                model.messages.insert(message, at: tempIndex)  // 실제 메시지 삽입

            }
            
            // DB 저장
            try await databaseRepository.saveMessage(message)
            
            // 메시지 전송 성공 시 MyPageView에 마지막 메시지 업데이트 알림 전송
            NotificationCenter.default.post(name: .lastMessageUpdated, object: (model.roomId, message.content))
            
            // 전송 상태 업데이트 및 UI 갱신
            model.sendingMessageId = nil
            model.updateMessagesGroupedByDate()  // 실제 메시지 교체 후에만 UI 갱신

            
        } catch {
            print("❌ 메시지 전송 실패: \(error.localizedDescription)")
            model.error = error.localizedDescription
            // 에러 발생 시 임시 메시지 제거
            model.messages.removeAll { $0.chatId == tempMessageId }
            model.sendingMessageId = nil
            model.updateMessagesGroupedByDate()
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
    
    private func loadPreviousMessages() async {
        // 이미 로딩 중이거나 더 이상 메시지가 없으면 리턴
        guard !model.isLoadingMoreMessages && model.hasMoreMessages else { return }
        
        // 초기 로드가 완료되지 않았으면 리턴
        guard model.isInitialLoadComplete else { return }
        
        model.isLoadingMoreMessages = true
        
        do {
            let pageSize = 50 // 한 번에 로드할 메시지 개수
            
            if let oldestDate = model.oldestLoadedDate {
                // 기존 사용자: 로컬 DB에서 이전 메시지 로드
                let previousMessages = try await databaseRepository.getMessagesBeforeDate(
                    roomId: model.roomId,
                    date: oldestDate,
                    limit: pageSize
                )
                
                if !previousMessages.isEmpty {
                    // 메시지를 앞쪽에 추가 (UI에서 상하반전되므로)
                    model.messages.insert(contentsOf: previousMessages, at: 0)
                    
                    // 가장 오래된 메시지 날짜 업데이트
                    if let newOldestMessage = previousMessages.min(by: { 
                        PresentationMapper.parseISO8601ToDate($0.createdAt) < PresentationMapper.parseISO8601ToDate($1.createdAt) 
                    }) {
                        model.oldestLoadedDate = PresentationMapper.parseISO8601ToDate(newOldestMessage.createdAt)
                    }
                    
                    // 더 로드할 메시지가 있는지 확인
                    let totalMessageCount = try await databaseRepository.getMessagesCount(roomId: model.roomId)
                    model.hasMoreMessages = totalMessageCount > model.messages.count
                    
                    // 메시지 그룹화 업데이트
                    model.updateMessagesGroupedByDate()
                    
                    print("📄 이전 메시지 로드 완료: \(previousMessages.count)개")
                } else {
                    // 로컬 DB에 더 이상 메시지가 없으면 서버에서 요청
                    await loadPreviousMessagesFromServer(oldestDate: oldestDate, pageSize: pageSize)
                }
            } else {
                // oldestLoadedDate가 없는 경우 (새 사용자) 서버에서 요청
                await loadPreviousMessagesFromServer(oldestDate: Date(), pageSize: pageSize)
            }
            
        } catch {
            model.error = error.localizedDescription
            print("❌ 이전 메시지 로드 실패: \(error.localizedDescription)")
        }
        
        model.isLoadingMoreMessages = false
    }
    
    private func loadPreviousMessagesFromServer(oldestDate: Date, pageSize: Int) async {
        do {
            // 서버에서 이전 메시지 요청
            let formattedDate = PresentationMapper.formatDateToISO8601(oldestDate)
            let chatList = try await repository.getChatList(
                roomId: model.roomId,
                from: formattedDate
            )
            
            if !chatList.chats.isEmpty {
                // DB에 저장
                try await databaseRepository.saveMessages(chatList.chats)
                
                // 메시지를 앞쪽에 추가 (UI에서 상하반전되므로)
                model.messages.insert(contentsOf: chatList.chats, at: 0)
                
                // 가장 오래된 메시지 날짜 업데이트
                if let newOldestMessage = chatList.chats.min(by: { 
                    PresentationMapper.parseISO8601ToDate($0.createdAt) < PresentationMapper.parseISO8601ToDate($1.createdAt) 
                }) {
                    model.oldestLoadedDate = PresentationMapper.parseISO8601ToDate(newOldestMessage.createdAt)
                }
                
                // 더 로드할 메시지가 있는지 확인
                // 현재 받은 메시지 개수가 pageSize보다 적으면 더 이상 메시지가 없는 것으로 판단
                if chatList.chats.count < pageSize {
                    model.hasMoreMessages = false
                    print("📭 서버에서 더 이상 메시지가 없습니다 (받은 메시지: \(chatList.chats.count)개)")
                } else {
                    // pageSize만큼 받았다면 더 있을 가능성이 있으므로 한 번 더 확인
                    if let oldestMessage = chatList.chats.min(by: { 
                        PresentationMapper.parseISO8601ToDate($0.createdAt) < PresentationMapper.parseISO8601ToDate($1.createdAt) 
                    }) {
                        let oldestDate = PresentationMapper.parseISO8601ToDate(oldestMessage.createdAt)
                        let olderChatList = try await repository.getChatList(
                            roomId: model.roomId, 
                            from: PresentationMapper.formatDateToISO8601(oldestDate)
                        )
                        model.hasMoreMessages = !olderChatList.chats.isEmpty
                        
                        if !olderChatList.chats.isEmpty {
                            print("📄 서버에 더 많은 메시지가 있습니다 (추가 확인: \(olderChatList.chats.count)개)")
                        } else {
                            print("📭 서버에서 더 이상 메시지가 없습니다 (추가 확인 결과)")
                        }
                    }
                }
                
                // 메시지 그룹화 업데이트
                model.updateMessagesGroupedByDate()
                
                print("🌐 서버에서 이전 메시지 로드 완료: \(chatList.chats.count)개")
            } else {
                // 서버에서 빈 배열을 반환한 경우 - 더 이상 메시지가 없음
                model.hasMoreMessages = false
                print("📭 서버에서 더 이상 메시지가 없습니다 (빈 응답)")
            }
            
        } catch {
            model.error = error.localizedDescription
            print("❌ 서버에서 이전 메시지 로드 실패: \(error.localizedDescription)")
            
            // 에러 발생 시에도 더 이상 시도하지 않도록 설정 (선택사항)
            // model.hasMoreMessages = false
        }
    }
    
    private func handleIncomingMessage(_ message: ChatMessageEntity) {
        Task {
            do {
                // 현재 사용자 정보 가져오기
                guard let userInfo = UserDefaultsManager.shared.getObject(forKey: .profileData, as: MyProfileInfoEntity.self) else {
                    print("⚠️ 사용자 정보를 찾을 수 없어 메시지를 무시합니다.")
                    return
                }
                
                // 자신이 보낸 메시지는 무시 (HTTP로 이미 처리됨)
                if message.sender == userInfo.userid {
                    print("⚠️ 자신이 보낸 메시지 무시: \(message.chatID)")
                    return
                }
                
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
                do {
                try await databaseRepository.saveMessage(chatEntity)
                model.messages.append(chatEntity)
                model.updateMessagesGroupedByDate()
                    
                    // newMessageButton 흔들림 처리
                    handleNewMessageButtonShake()
                
                } catch {
                    print("⚠️ 메시지 저장 중 오류 발생 (중복 가능성): \(error.localizedDescription)")
                    // 중복 키 오류인 경우 UI에만 추가 (DB는 이미 존재할 수 있음)
                    if error.localizedDescription.contains("primary key") || error.localizedDescription.contains("existing") {
                        model.messages.append(chatEntity)
                        model.updateMessagesGroupedByDate()
                        handleNewMessageButtonShake()
                        
                    }
                }
                
                // 채팅방 목록의 마지막 메시지는 서버 동기화 시에만 업데이트
                // (기존 아키텍처에 맞춰 WebSocket 메시지는 DB에만 저장)
            } catch {
                print("❌ 메시지 저장 실패: \(error.localizedDescription)")
                // 에러가 발생해도 채팅은 계속 진행 (model.error 설정하지 않음)
            }
        }
    }
    
    // MARK: - newMessageButton 흔들림 처리
    private func handleNewMessageButtonShake() {
        // 이미 흔들림 상태라면 추가 흔들림
        if model.shouldShakeNewMessageButton {
            // 흔들림 상태를 잠시 해제했다가 다시 활성화
            model.shouldShakeNewMessageButton = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.model.shouldShakeNewMessageButton = true
            }
        } else {
            // 첫 번째 흔들림
            model.shouldShakeNewMessageButton = true
        }
        
        // 1초 후 흔들림 상태 해제
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.model.shouldShakeNewMessageButton = false
        }
    }
    
    // MARK: - 파일 검증
    private func validateFiles(_ files: [SelectedFile]) {
        let maxFileSize = 5 * 1024 * 1024 // 5MB
        let allowedExtensions = ["jpg", "jpeg", "png", "gif", "pdf"]
        
        var newInvalidIndices: Set<Int> = []
        var newInvalidReasons: [Int: String] = [:]
        var hasDuplicate = false
        
        // 중복 파일 검사
        let fileNames = files.map { $0.fileName }
        let uniqueFileNames = Set(fileNames)
        if fileNames.count != uniqueFileNames.count {
            hasDuplicate = true
        }
        
        for (index, file) in files.enumerated() {
            let fileData = file.data ?? file.image?.jpegData(compressionQuality: 0.8) ?? Data()
            let fileExtension = file.fileExtension.lowercased()
            
            // 크기 검증
            let isSizeValid = fileData.count <= maxFileSize
            // 확장자 검증
            let isExtensionValid = allowedExtensions.contains(fileExtension)
            
            if !isSizeValid || !isExtensionValid {
                newInvalidIndices.insert(index)
                
                // 구체적인 원인 감지
                var reasons: [String] = []
                if !isSizeValid {
                    let formatter = ByteCountFormatter()
                    formatter.allowedUnits = [.useKB, .useMB]
                    formatter.countStyle = .file
                    let fileSizeString = formatter.string(fromByteCount: Int64(fileData.count))
                    let maxSizeString = formatter.string(fromByteCount: Int64(maxFileSize))
                    reasons.append("크기: \(fileSizeString) (제한: \(maxSizeString))")
                }
                if !isExtensionValid {
                    reasons.append("확장자: \(fileExtension.uppercased()) (지원: JPG, PNG, GIF, PDF)")
                }
                
                newInvalidReasons[index] = reasons.joined(separator: ", ")
                
                print("❌ 유효하지 않은 파일: \(file.fileName)")
                print("   - 원인: \(reasons.joined(separator: ", "))")
            }
        }
        
        // 유효하지 않은 파일 정보 업데이트
        model.invalidFileIndices = newInvalidIndices
        model.invalidFileReasons = newInvalidReasons
        
        // 중복 파일이 감지된 경우 토스트 표시
        if hasDuplicate {
            model.toast = FancyToast(
                type: .warning,
                title: "중복 파일",
                message: "중복된 파일이 포함되어 있습니다.",
                duration: 3.0
            )
            print("⚠️ 중복된 파일이 감지되었습니다")
        }
        // 유효하지 않은 파일이 새로 추가된 경우 토스트 표시
        else if !newInvalidIndices.isEmpty {
            // 유효하지 않은 파일들의 이름을 가져와서 토스트 메시지 생성
            let invalidFileNames = newInvalidReasons.keys.compactMap { index in
                if index < files.count {
                    return files[index].fileName
                }
                return nil
            }
            let message = "유효하지 않은 파일이 있습니다: \(invalidFileNames.joined(separator: ", "))"
            
            model.toast = FancyToast(
                type: .error,
                title: "파일 오류",
                message: message,
                duration: 5.0
            )
            print("⚠️ 유효하지 않은 파일이 감지되었습니다: \(newInvalidIndices.count)개")
        }
    }
    
    deinit {
        socket?.disconnect()
    }
    
    // MARK: - 앱 생명주기 이벤트 처리
    private func setupAppLifecycleObserver() {
        // SceneDelegate에서 전송하는 채팅 소켓 제어 알림
        NotificationCenter.default
            .publisher(for: .chatSocketShouldDisconnect)
            .sink { [weak self] _ in
                print("🔵 SceneDelegate: 채팅 소켓 해제 요청")
                self?.handleAppDidEnterBackground()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default
            .publisher(for: .chatSocketShouldReconnect)
            .sink { [weak self] _ in
                print("🟢 SceneDelegate: 채팅 소켓 재연결 요청")
                self?.handleAppWillEnterForeground()
            }
            .store(in: &cancellables)
        
        // 앱이 활성화될 때 (포그라운드 진입 후)
        NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                print("🟢 앱이 활성화됨 - 채팅 소켓 상태 확인")
                self?.handleAppDidBecomeActive()
            }
            .store(in: &cancellables)
    }
    
    private func handleAppDidEnterBackground() {
        // 백그라운드 진입 시 소켓 해제
        print("🔵 채팅 소켓 해제 중...")
        socket?.disconnect()
        model.isConnected = false
    }
    
    private func handleAppWillEnterForeground() {
        // 포그라운드 진입 시 소켓 재연결 준비
        print("🟢 채팅 소켓 재연결 준비 중...")
        // 실제 연결은 didBecomeActive에서 처리
    }
    
    private func handleAppDidBecomeActive() {
        // 앱이 활성화된 후 소켓 재연결
        guard !model.isConnected else {
            print("🟢 이미 연결된 상태 - 재연결 불필요")
            return
        }
        
        print("🟢 채팅 소켓 재연결 시도...")
        socket?.connect()
    }
    
    // 재연결 시도 메서드 추가
    private func attemptReconnect() {
        guard !model.isReconnecting else { return }
        
        model.isReconnecting = true
        let maxAttempts = 5
        let baseDelay = 1.0 // 초기 지연 시간 (초)
        
        func tryReconnect(attempt: Int) {
            guard attempt < maxAttempts else {
                model.isReconnecting = false
                model.error = "연결을 재설정할 수 없습니다. 앱을 다시 시작해주세요."
                return
            }
            
            let delay = baseDelay * pow(2.0, Double(attempt)) // exponential backoff
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.handle(.initialLoad)
            }
        }
        
        tryReconnect(attempt: model.reconnectAttempts)
        model.reconnectAttempts += 1
    }
}   
