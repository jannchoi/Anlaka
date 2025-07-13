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
}
enum MyPageIntent {
    case initialRequest
}

@MainActor
final class MyPageContainer: ObservableObject {
    @Published var model = MyPageModel()
    private let repository: NetworkRepository

    init(repository: NetworkRepository) {
        self.repository = repository
    }
    func handle(_ intent: MyPageIntent) {
        switch intent {
        case .initialRequest:
            Task {
                await getMyProfileInfo()
                await getChatRoomList()
            }
        }
    }
    private func getMyProfileInfo()  {
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
                let chatRoomList = try await repository.getChatRooms()
                model.chatRoomList = chatRoomList.rooms
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
    

