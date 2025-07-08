//
//  DIContainer.swift
//  Anlaka
//
//  Created by 최정안 on 5/12/25.
//

import Foundation

@MainActor
final class DIContainer: ObservableObject {
    private let networkRepository: NetworkRepository
    private let databaseRepository: DatabaseRepository
    
    init() throws {
        self.networkRepository = NetworkRepositoryFactory.create()
        self.databaseRepository = try DatabaseRepositoryFactory.create()
    }
    
    // MARK: - Static Factory Method
    static func create() throws -> DIContainer {
        return try DIContainer()
    }
    
    // MARK: - Container Factory Methods
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
    func makeEditProfieContainer() -> EditProfileContainer {
        EditProfileContainer(repository: networkRepository)
    }
    
    func makeEstateDetailContainer(estateId: String) -> EstateDetailContainer {
        EstateDetailContainer(repository: networkRepository, estateId: estateId)
    }
    func makeEstateDetailContainer(estate: DetailEstateEntity) -> EstateDetailContainer {
        EstateDetailContainer(repository: networkRepository, estate: estate)
    }
    func makePaymentContainer(iamportPayment: IamportPaymentEntity) -> PaymentContainer {
        PaymentContainer(repository: networkRepository, iamportPayment: iamportPayment)
    }
}
