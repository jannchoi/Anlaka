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
    private let addressNetworkRepository: AddressNetworkRepository
    private let communityNetworkRepository: CommunityNetworkRepository
    private let databaseRepository: DatabaseRepository
    private let locationService: LocationService
    
    init() throws {
        self.networkRepository = NetworkRepositoryFactory.create()
        self.addressNetworkRepository = AddressNetworkRepositoryFactory.create()
        self.communityNetworkRepository = CommunityNetworkRepositoryFactory.create()
        self.databaseRepository = try DatabaseRepositoryFactory.create()
        self.locationService = LocationServiceFactory.create() // Factory로 생성
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
        let homeUseCase = HomeUseCase(
            networkRepository: networkRepository,
            addressRepository: addressNetworkRepository
        )
        return HomeContainer(useCase: homeUseCase)
    }
    func makeSearchMapContainer() -> SearchMapContainer {
        SearchMapContainer(repository: networkRepository, locationService: locationService)
    }
    func makeSearchAddressContainer() -> SearchAddressContainer {
        SearchAddressContainer(repository: addressNetworkRepository)
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
    func makeCommunityContainer() -> CommunityContainer {
        let postSummaryUseCase = PostSummaryUseCase(
            communityRepository: communityNetworkRepository,
            addressRepository: addressNetworkRepository
        )
        return CommunityContainer(repository: communityNetworkRepository, useCase: postSummaryUseCase, locationService: locationService)
    }
    
    func makePostDetailContainer(postId: String) -> PostDetailContainer {
        let postingUseCase = PostingUseCase(
            communityRepository: communityNetworkRepository,
            addressRepository: addressNetworkRepository
        )
        return PostDetailContainer(useCase: postingUseCase, postId: postId)
    }

    // PostingContainer 생성자 통합
    func makePostingContainer(post: PostResponseEntity? = nil) -> PostingContainer {
        let postingUseCase = PostingUseCase(
            communityRepository: communityNetworkRepository,
            addressRepository: addressNetworkRepository
        )
        return PostingContainer(post: post, postingUseCase: postingUseCase, locationService: locationService)
    }
}
