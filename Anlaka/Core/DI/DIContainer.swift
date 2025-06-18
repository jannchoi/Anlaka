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
    
    init(networkRepository: NetworkRepository) {
        self.networkRepository = networkRepository
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
        MyPageContainer(repository: networkRepository)
    }
    func makeChattingContainer(roomId: String) -> ChattingContainer {
        ChattingContainer(repository: networkRepository, roomId: roomId)
    }
}
