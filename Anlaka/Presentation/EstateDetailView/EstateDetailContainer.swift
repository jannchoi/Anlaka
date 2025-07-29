//
//  EstateDetailContainer.swift
//  Anlaka
//
//  Created by 최정안 on 6/8/25.
//

import Foundation

struct EstateDetailModel {
    var errorMessage: String? = nil
    var detailEstate: Loadable<DetailEstateWithAddrerss> = .idle
    var similarEstates: Loadable<[SimilarEstateWithAddress]> = .idle
    var selectedEstateId: IdentifiableString? = nil
    let curEstateid: String
    var order: CreateOrderRequestDTO? = nil
    var iamportPayment: IamportPaymentEntity? = nil
    var estateTitle: String? = nil
    var isReserved = false
    var isLiked = false
    var backToLogin: Bool = false
    var opponent_id: String? = nil
}

enum EstateDetailIntent {
    case initialRequest
    case similarEstateSelected(estateId: String)
    case reserveButtonTapped
    case likeButtonTapped
    case chatButtonTapped
    case resetPayment
    case resetReservation
}

// MARK: - EstateDetailContainer 초기화 메서드 수정
@MainActor
final class EstateDetailContainer: ObservableObject {
    @Published var model : EstateDetailModel
    private let repository: NetworkRepository
    private let initializationType: InitializationType
    
    enum InitializationType {
        case estateId(String)
        case estate(DetailEstateEntity)
    }
    
    init(repository: NetworkRepository, estateId: String) {
        self.repository = repository
        self.initializationType = .estateId(estateId)
        self.model = EstateDetailModel(curEstateid: estateId)
    }
    
    init(repository: NetworkRepository, estate: DetailEstateEntity) {
        self.repository = repository
        self.initializationType = .estate(estate)
        self.model = EstateDetailModel(curEstateid: estate.estateId)
    }
    
    func handle(_ intent: EstateDetailIntent) {
        switch intent {
        case .initialRequest:
            Task {
                switch initializationType {
                case .estateId(let estateId):
                    await getDetailEstate(estateId: estateId)
                case .estate(let estate):
                    await mapToEstateDetailWithAddress(estate: estate)
                }
                await getSimilarEstate()
            }
        case .similarEstateSelected(let estateId):
            model.selectedEstateId = IdentifiableString(id: estateId)
        case .reserveButtonTapped:
            if !model.isReserved && model.iamportPayment == nil {
                Task {
                    await createOrder()
                }
            }
        case .likeButtonTapped:
            Task {
                await toggleIsLiked()
            }
        case .chatButtonTapped:
            if case .success(let data) = model.detailEstate {
                // 이미 처리 중이면 무시
                guard model.opponent_id == nil else { return }
                
                model.opponent_id = data.detail.creator.userId
            }
        case .resetPayment:
            model.iamportPayment = nil
        case .resetReservation:
            model.isReserved = false
            model.iamportPayment = nil
        }
    }
    private func createOrder() async {
        guard let order = model.order, let estateTitle = model.estateTitle , let savedProfile = UserDefaultsManager.shared.getObject(forKey: .profileData, as: MyProfileInfoEntity.self) else {
            return
        }
        do {
            let result = try await repository.createOrder(order: order)
            model.iamportPayment = IamportPaymentEntity(orderCode: result.orderCode, amount: String(result.totalPrice), title: estateTitle, buyerName: savedProfile.nick)
            model.isReserved = true
        } catch {
            print("error: \(error)")
        }
        
    }
    private func toggleIsLiked() async {
        
        do {
            let result = try await repository.postLikeEstate(model.curEstateid, LikeEstateEntity(likeStatus: !model.isLiked))
            model.isLiked = result.likeStatus
        } catch {
            print("error: \(error)")
        }
    }
    private func mapToEstateDetailWithAddress(estate: DetailEstateEntity) async {
        model.detailEstate = .loading
        let result = await AddressMappingHelper.mapDetailEstateWithAddress(estate, repository: repository)
        switch result {
        case .success(let value):
            model.detailEstate = .success(value)
        case .failure(let error):
            if let netError = error as? NetworkError, netError == .expiredRefreshToken {
                model.detailEstate = .requiresLogin
            } else {
                let message = (error as? NetworkError)?.errorDescription ?? error.localizedDescription
                model.detailEstate = .failure(message)
                model.errorMessage = message
            }
        }
    }
    
    private func getDetailEstate(estateId: String) async {
        model.detailEstate = .loading
        do {
            let detailEstate = try await repository.getDetailEstate(estateId)
            if let reservationPrice = detailEstate.reservationPrice {
                model.order = CreateOrderRequestDTO(estateId: estateId, totalPrice: reservationPrice)
            }
            let result = await AddressMappingHelper.mapDetailEstateWithAddress(detailEstate, repository: repository)
            switch result {
            case .success(let value):
                model.isLiked = value.detail.isLiked
                model.isReserved = value.detail.isReserved
                model.detailEstate = .success(value)
                model.estateTitle = value.detail.title
                print(value.detail.reservationPrice)
            case .failure(let error):
                if let netError = error as? NetworkError, netError == .expiredRefreshToken {
                    model.detailEstate = .requiresLogin
                } else {
                    let message = (error as? NetworkError)?.errorDescription ?? error.localizedDescription
                    model.detailEstate = .failure(message)
                    model.errorMessage = message
                }
            }
        } catch {
            if let netError = error as? NetworkError, netError == .expiredRefreshToken {
                model.detailEstate = .requiresLogin
            } else {
                let message = (error as? NetworkError)?.errorDescription ?? error.localizedDescription
                model.detailEstate = .failure(message)
                model.errorMessage = message
            }
        }
    }
    
    private func getSimilarEstate() async {
        model.similarEstates = .loading
        do {
            let summaries = try await repository.getSimilarEstate()
            let result = await AddressMappingHelper.mapSimilarSummariesWithAddress(summaries.data, repository: repository)
            
            model.similarEstates = .success(result.estates)
            
            if let firstError = result.errors.first {
                model.errorMessage = (firstError as? NetworkError)?.errorDescription ?? firstError.localizedDescription
            }
        } catch {
            if let netError = error as? NetworkError, netError == .expiredRefreshToken {
                model.similarEstates = .requiresLogin
            } else {
                let message = (error as? NetworkError)?.errorDescription ?? error.localizedDescription
                model.similarEstates = .failure(message)
            }
        }
    }
}
