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
                        if serverRoom.updatedAt > localRoom.updatedAt {
                            updatedRoomIds.insert(serverRoom.roomId)
                        }
                        roomsToUpdate.append(serverRoom)
                    } else {
                        // 새로운 방인 경우
                        roomsToUpdate.append(serverRoom)
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
                model.updatedRoomIds = updatedRoomIds
                
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
}
    


