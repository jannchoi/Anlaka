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
}
