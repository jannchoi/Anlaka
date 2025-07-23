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
}

enum MyPageIntent {
    case initialRequest
    case addMyEstate
}

@MainActor
final class MyPageContainer: ObservableObject {
    @Published var model = MyPageModel()
    private let repository: NetworkRepository
    private let databaseRepository: DatabaseRepository

    init(repository: NetworkRepository, databaseRepository: DatabaseRepository) {
        self.repository = repository
        self.databaseRepository = databaseRepository
    }
    
    func handle(_ intent: MyPageIntent) {
        switch intent {
        case .initialRequest:
                 getMyProfileInfo()
                 getChatRoomList()
            
        case .addMyEstate:
            uploadAdminRequest()
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
                if let netError = error as? NetworkError, netError == .expiredRefreshToken {
                    model.backToLogin = true
                } else {
                    let message = (error as? NetworkError)?.errorDescription ?? error.localizedDescription
                    model.errorMessage = message
                }
            }
        }
    }
    
    private func getMyProfileInfo() {
        guard let myProfile = UserDefaultsManager.shared.getObject(forKey: .profileData, as: MyProfileInfoEntity.self) else {
            Task {
                do {
                    let myProfile = try await repository.getMyProfileInfo()
                    model.profileInfo = myProfile
                } catch {
                    print("❌ Failed to get my profile info: \(error)")
                    if let netError = error as? NetworkError, netError == .expiredRefreshToken {
                        model.backToLogin = true
                    } else {
                        let message = (error as? NetworkError)?.errorDescription ?? error.localizedDescription
                        model.errorMessage = message
                    }
                }
            }
            return
        }
        model.profileInfo = myProfile
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
                
                // 5. UI 갱신
                model.chatRoomList = roomsToUpdate
                model.updatedRoomIds = updatedRoomIds // hasNewChat 표시할 채팅방 ID들
                
                print("📱 UI 업데이트 완료 - 새로운 채팅이 있는 방: \(updatedRoomIds)")
                
            } catch {
                print("❌ Failed to get chat room list: \(error)")
                if let netError = error as? NetworkError, netError == .expiredRefreshToken {
                    model.backToLogin = true
                } else {
                    let message = (error as? NetworkError)?.errorDescription ?? error.localizedDescription
                    model.errorMessage = message
                }
            }
        }
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
}
    


