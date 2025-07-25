//
//  ProfileContainer.swift
//  Anlaka
//
//  Created by 최정안 on 6/9/25.
//

import Foundation

struct MyPageModel {
    var profileInfo: MyProfileInfoEntity? = nil
    var chatRoomList: [ChatRoomEntity] = []
    var backToLogin: Bool = false
    var errorMessage: String? = nil
    var updatedRoomIds: Set<String> = []
    var isInitialized: Bool = false
}

enum MyPageIntent {
    case initialRequest
    case refreshData
    case addMyEstate
    case logout
}

@MainActor
final class MyPageContainer: ObservableObject {
    @Published var model = MyPageModel()
    private let repository: NetworkRepository
    private let databaseRepository: DatabaseRepository
    private var notificationObserver: NSObjectProtocol?

    init(repository: NetworkRepository, databaseRepository: DatabaseRepository) {
        self.repository = repository
        self.databaseRepository = databaseRepository
        
        // 포그라운드 진입 알림 구독
        setupNotificationObserver()
    }
    
    deinit {
        // 알림 구독 해제
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    func handle(_ intent: MyPageIntent) {
        switch intent {
        case .initialRequest:
            // 이미 초기화된 경우 중복 로드 방지
            guard !model.isInitialized else { return }
            
            getMyProfileInfo()
            getChatRoomList()
            
            model.isInitialized = true
            
        case .refreshData:
            print("📱 채팅방 목록 새로고침 시작")
            
            // 기존 데이터를 초기화한 후 다시 로드
            model.profileInfo = nil
            model.chatRoomList = []
            model.updatedRoomIds = []
            model.isInitialized = false
            
            getMyProfileInfo()
            getChatRoomList()
            
            model.isInitialized = true
            
            //print("📱 채팅방 목록 새로고침 완료")
            

            
        case .addMyEstate:
            uploadAdminRequest()
        case .logout:
            // 로그아웃 처리
            logout()
        }
    }
    private func uploadAdminRequest() {
        Task {
            do {
                let adminRequest = AdminRequestMockData()
                print("🍿🍿🍿",adminRequest)
                let response = try await repository.uploadAdminRequest(adminRequest: adminRequest)
                print("🧶🧶🧶",response)
            } catch {
                print("❌ Failed to upload admin request: \(error)")
                if let netError = error as? CustomError, netError == .expiredRefreshToken {
                    print("🔐 Refresh Token 만료 - 자동 로그아웃 처리")
                    handleRefreshTokenExpiration()
                } else {
                    let message = (error as? CustomError)?.errorDescription ?? error.localizedDescription
                    model.errorMessage = message
                }
            }
        }
    }
    
    private func getMyProfileInfo() {
        Task {
            do {
                let myProfile = try await repository.getMyProfileInfo()
                // 서버에서 받은 최신 프로필 정보를 UserDefaults에 저장
                UserDefaultsManager.shared.setObject(myProfile, forKey: .profileData)
                model.profileInfo = myProfile
            } catch {
                print("❌ Failed to get my profile info: \(error)")
                if let netError = error as? CustomError, netError == .expiredRefreshToken {
                    print("🔐 Refresh Token 만료 - 자동 로그아웃 처리")
                    handleRefreshTokenExpiration()
                } else {
                    let message = (error as? CustomError)?.errorDescription ?? error.localizedDescription
                    model.errorMessage = message
                }
            }
        }
    }
    
    private func getChatRoomList() {
        Task {
            do {
                // 1. 서버에서 최신 채팅방 목록 동기화
                let serverRooms = try await repository.getChatRooms()
                // 2. 서버에서 받은 채팅방 목록이 비어있는 경우 DB 초기화
                if serverRooms.rooms.isEmpty {
                    try await databaseRepository.resetDatabase()
                    model.chatRoomList = []
                    model.updatedRoomIds = []
                    return
                }
                
                // 3. 로컬 DB에서 채팅방 목록 로드
                let localRooms = try await databaseRepository.getChatRooms()
                
                // 4. 새로운 채팅이 있는 채팅방 ID 확인 및 DB 동기화
                var updatedRoomIds = Set<String>()
                var roomsToUpdate: [ChatRoomEntity] = []
                
                // 4-1. 서버의 채팅방 목록 순회
                for serverRoom in serverRooms.rooms {
                    if let localRoom = localRooms.first(where: { $0.roomId == serverRoom.roomId }) {
                        // 기존 방이 있는 경우
                        var shouldUpdate = false
                        
                        // 1) 채팅 메시지 업데이트 확인 (서버 가이드에 따름)
                        // 서버의 updatedAt이 로컬DB의 updatedAt보다 크면 새로운 채팅이 있음을 의미
                        if serverRoom.updatedAt > localRoom.updatedAt {
                            shouldUpdate = true
                            updatedRoomIds.insert(serverRoom.roomId) // hasNewChat 표시용
                            print("🆕 새로운 채팅 발견: \(serverRoom.roomId), 서버: \(serverRoom.updatedAt), 로컬: \(localRoom.updatedAt)")
                            
                            // 서버에서 최신 마지막 메시지 정보로 DB 업데이트
                            if let serverLastChat = serverRoom.lastChat {
                                // 서버의 최신 마지막 메시지로 채팅방 정보 업데이트
                                let updatedRoom = ChatRoomEntity(
                                    roomId: serverRoom.roomId,
                                    createdAt: serverRoom.createdAt,
                                    updatedAt: serverRoom.updatedAt,
                                    participants: serverRoom.participants,
                                    lastChat: serverRoom.lastChat
                                )
                                try await databaseRepository.updateChatRoom(updatedRoom)
                                
                                // 서버 데이터가 있으면 임시 메시지 제거
                                TemporaryLastMessageManager.shared.removeTemporaryLastMessage(for: serverRoom.roomId)
                                
                                //print("📱 채팅방 \(serverRoom.roomId) 마지막 메시지 서버 동기화 완료 및 임시 메시지 제거")
                            }
                        }
                        
                        // 2) 프로필 정보 변경 확인 (채팅 메시지는 없지만 프로필이 변경된 경우)
                        let profileChanged = hasProfileChanged(serverRoom: serverRoom, localRoom: localRoom)
                        if profileChanged {
                            shouldUpdate = true
                            print("👤 프로필 정보 변경: \(serverRoom.roomId)")
                        }
                        
                        if shouldUpdate {
                            roomsToUpdate.append(serverRoom)
                        } else {
                            // 업데이트가 필요없으면 기존 로컬 데이터 사용
                            roomsToUpdate.append(localRoom)
                        }
                    } else {
                        // 새로운 방인 경우
                        roomsToUpdate.append(serverRoom)
                        print("🆕 새로운 채팅방: \(serverRoom.roomId)")
                    }
                }
                
                // 4-2. DB에는 있지만 서버에는 없는 방 제거
                let serverRoomIds = Set(serverRooms.rooms.map { $0.roomId })
                let localRoomIds = Set(localRooms.map { $0.roomId })
                let roomsToDelete = localRoomIds.subtracting(serverRoomIds)
                
                // 4-3. DB 업데이트
                try await databaseRepository.saveChatRooms(roomsToUpdate)
                for roomId in roomsToDelete {
                    try await databaseRepository.deleteChatRoom(roomId: roomId)
                }
                

                
                // 5. 임시 마지막 메시지로 UI 업데이트
                let notificationCountManager = ChatNotificationCountManager.shared
                let temporaryMessageManager = TemporaryLastMessageManager.shared
                var finalRoomsToUpdate: [ChatRoomEntity] = []
                
                for room in roomsToUpdate {
                    var updatedRoom = room
                    
                    // 임시 마지막 메시지가 있으면 우선 사용
                    if let tempMessage = temporaryMessageManager.getTemporaryLastMessage(for: room.roomId) {
                        // 임시 마지막 메시지로 ChatEntity 생성
                        let tempChatEntity = ChatEntity(
                            chatId: "temp_\(UUID().uuidString)",
                            roomId: room.roomId,
                            content: tempMessage.content,
                            createdAt: PresentationMapper.formatDateToISO8601(tempMessage.timestamp),
                            updatedAt: PresentationMapper.formatDateToISO8601(tempMessage.timestamp),
                            sender: tempMessage.senderId,
                            files: tempMessage.hasFiles ? ["temp_file"] : []
                        )
                        
                        updatedRoom = ChatRoomEntity(
                            roomId: room.roomId,
                            createdAt: room.createdAt,
                            updatedAt: room.updatedAt,
                            participants: room.participants,
                            lastChat: tempChatEntity
                        )
                        print("📱 채팅방 \(room.roomId) 임시 마지막 메시지 사용: \(tempMessage.content)")
                        
                        // 임시 메시지가 있는 채팅방은 updatedRoomIds에 추가
                        updatedRoomIds.insert(room.roomId)
                    }
                    
                    finalRoomsToUpdate.append(updatedRoom)
                }
                    
                // 6. 알림 카운트가 있는 채팅방들을 updatedRoomIds에 추가 (서버 데이터와 무관하게 보존)
                for room in finalRoomsToUpdate {
                    if notificationCountManager.getCount(for: room.roomId) > 0 {
                        updatedRoomIds.insert(room.roomId)
                        print("📱 채팅방 \(room.roomId) 알림 카운트 보존: \(notificationCountManager.getCount(for: room.roomId))")
                    }
                }
                
                // 7. UI 갱신
                model.chatRoomList = finalRoomsToUpdate
                model.updatedRoomIds = updatedRoomIds // hasNewChat 표시할 채팅방 ID들
                
                //print("📱 UI 업데이트 완료 - 새로운 채팅이 있는 방: \(updatedRoomIds)")
                
            } catch {
                print("❌ Failed to get chat room list: \(error)")
                if let netError = error as? CustomError, netError == .expiredRefreshToken {
                    print("🔐 Refresh Token 만료 - 자동 로그아웃 처리")
                    handleRefreshTokenExpiration()
                } else {
                    let message = (error as? CustomError)?.errorDescription ?? error.localizedDescription
                    model.errorMessage = message
                }
            }
        }
    }
    
    /// 채팅 알림 업데이트 구독 설정
    private func setupNotificationObserver() {
        // 포그라운드 진입 알림 구독
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .appDidEnterForeground,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("📱 MyPageContainer에서 포그라운드 진입 알림 수신")
            self?.updateChatRoomListFromBackground()
        }
        
        // 채팅 알림 업데이트 구독 (디바운싱 적용)
        var updateTimer: Timer?
        NotificationCenter.default.addObserver(
            forName: .chatNotificationUpdate,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            //print("📱 MyPageContainer에서 채팅 알림 업데이트 수신")
            
            // 이전 타이머 취소
            updateTimer?.invalidate()
            
            // 0.5초 후에 업데이트 실행 (디바운싱)
            updateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                self?.updateChatRoomListFromBackground()
            }
        }
    }
    
    /// 채팅 알림 업데이트 - updatedRoomIds만 업데이트하여 개별 셀 ViewModel이 처리하도록 함
    private func updateChatRoomListFromBackground() {
        //print("📱 MyPageContainer - 채팅 알림 업데이트 시작")
        let notificationCountManager = ChatNotificationCountManager.shared
        let temporaryMessageManager = TemporaryLastMessageManager.shared
        var updatedRoomIds = Set<String>()
        
        //print("📱 현재 채팅방 목록 개수: \(model.chatRoomList.count)")
        
        // 임시 메시지가 있거나 알림 카운트가 있는 채팅방들을 updatedRoomIds에 추가
        for room in model.chatRoomList {
            let hasTempMessage = temporaryMessageManager.getTemporaryLastMessage(for: room.roomId) != nil
            let hasNotificationCount = notificationCountManager.getCount(for: room.roomId) > 0
            
            if hasTempMessage || hasNotificationCount {
                updatedRoomIds.insert(room.roomId)
                if hasTempMessage {
                    let tempMessage = temporaryMessageManager.getTemporaryLastMessage(for: room.roomId)!
                    print("📱 알림 업데이트 - 채팅방 \(room.roomId) 임시 메시지: \(tempMessage.content)")
                }
                if hasNotificationCount {
                    let count = notificationCountManager.getCount(for: room.roomId)
                    print("📱 알림 업데이트 - 채팅방 \(room.roomId) 알림 카운트: \(count)")
                }
            }
        }
        
        // updatedRoomIds만 업데이트 (전체 배열 수정 방지)
        model.updatedRoomIds = updatedRoomIds
        print("📱 알림 업데이트 완료 - 업데이트된 채팅방: \(updatedRoomIds)")
        //print("📱 총 알림 카운트: \(notificationCountManager.totalCount)")
    }
    
    // 프로필 정보 변경 확인 헬퍼 메서드
    private func hasProfileChanged(serverRoom: ChatRoomEntity, localRoom: ChatRoomEntity) -> Bool {
        // 서버와 로컬의 participants 수가 다르면 변경된 것으로 간주
        if serverRoom.participants.count != localRoom.participants.count {
            return true
        }
        
        // 각 participant의 프로필 정보 비교
        for serverParticipant in serverRoom.participants {
            if let localParticipant = localRoom.participants.first(where: { $0.userId == serverParticipant.userId }) {
                // 프로필 정보가 다르면 변경된 것으로 간주
                if serverParticipant.nick != localParticipant.nick ||
                   serverParticipant.introduction != localParticipant.introduction ||
                   serverParticipant.profileImage != localParticipant.profileImage {
                    return true
                }
            } else {
                // 새로운 참여자가 추가된 경우
                return true
            }
        }
        
        return false
    }

    private func logout() {
        print("🔐 로그아웃 시작")
        
        // 토큰 및 프로필 데이터 제거
        UserDefaultsManager.shared.removeObject(forKey: .accessToken)
        UserDefaultsManager.shared.removeObject(forKey: .refreshToken)
        UserDefaultsManager.shared.removeObject(forKey: .profileData)
        
        // 알림 관련 데이터 초기화
        ChatNotificationCountManager.shared.clearAllCounts()
        TemporaryLastMessageManager.shared.clearAllTemporaryMessages()
        CustomNotificationManager.shared.clearAllNotifications()
        
        // model 업데이트 (View에서 @AppStorage 처리)
        model.backToLogin = true
        print("🔐 model.backToLogin 설정 완료: true")
    }
    
    /// Refresh Token 만료 시 자동 로그아웃 처리
    private func handleRefreshTokenExpiration() {
        print("🔐 Refresh Token 만료 - 자동 로그아웃 처리 시작")
        
        // 토큰 및 프로필 데이터 제거
        UserDefaultsManager.shared.removeObject(forKey: .accessToken)
        UserDefaultsManager.shared.removeObject(forKey: .refreshToken)
        UserDefaultsManager.shared.removeObject(forKey: .profileData)
        
        // 알림 관련 데이터 초기화
        ChatNotificationCountManager.shared.clearAllCounts()
        TemporaryLastMessageManager.shared.clearAllTemporaryMessages()
        CustomNotificationManager.shared.clearAllNotifications()
        
        // model 업데이트 (View에서 @AppStorage 처리)
        model.backToLogin = true
        print("🔐 Refresh Token 만료 - model.backToLogin 설정 완료: true")
    }

}
    


