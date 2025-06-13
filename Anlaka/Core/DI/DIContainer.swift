//
//  DIContainer.swift
//  Anlaka
//
//  Created by 최정안 on 5/12/25.
//

import Foundation

@MainActor
final class DIContainer: ObservableObject {
    let networkRepository: NetworkRepository
    private let databaseRepository: DatabaseRepository
    init(networkRepository: NetworkRepository, databaseRepository: DatabaseRepository) {
        self.networkRepository = networkRepository
        self.databaseRepository = databaseRepository
    }
    func makeLoginContainer() -> LoginContainer {
        LoginContainer(repository: networkRepository)
    }
    func makeSignUpContainer() -> SignUpContainer {
        SignUpContainer(repository: networkRepository)
    }
    func makeHomeContainer() -> HomeContainer {
        HomeContainer(repository: networkRepository)
    }
    func makeSearchMapContainer() -> SearchMapContainer {
        SearchMapContainer(repository: networkRepository)
    }
    func makeSearchAddressContainer() -> SearchAddressContainer {
        SearchAddressContainer(repository: networkRepository)
    }
    func makeMyPageContainer() -> MyPageContainer {
        MyPageContainer(repository: networkRepository, databaseRepository: databaseRepository)
    }
    func makeChattingContainer(opponent_id: String) -> ChattingContainer {
        ChattingContainer(repository: networkRepository, databaseRepository: databaseRepository, opponent_id: opponent_id)
    }
    func makeChattingContainer(roomId: String) -> ChattingContainer {
        ChattingContainer(repository: networkRepository, databaseRepository: databaseRepository, roomId: roomId)
    }
}
