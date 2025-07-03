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
                // 1. 로컬 DB에서 채팅방 목록 로드
                let localRooms = try await databaseRepository.getChatRooms()
                model.chatRoomList = localRooms
                
                // 2. 서버에서 최신 채팅방 목록 동기화
                let serverRooms = try await repository.getChatRooms()
                
                // 3. 새로운 채팅이 있는 채팅방 ID 확인
                var updatedRoomIds = Set<String>()
                for serverRoom in serverRooms.rooms {
                    if let localRoom = localRooms.first(where: { $0.roomId == serverRoom.roomId }) {
                        if serverRoom.updatedAt > localRoom.updatedAt {
                            updatedRoomIds.insert(serverRoom.roomId)
                        }
                    }
                }
                
                // 4. DB 업데이트 및 UI 갱신
                try await databaseRepository.saveChatRooms(serverRooms.rooms)
                model.chatRoomList = serverRooms.rooms
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
    

