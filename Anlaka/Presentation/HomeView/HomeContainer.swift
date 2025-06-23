//
//  HomeContainer.swift
//  Anlaka
//
//  Created by 최정안 on 5/18/25.
//

import Foundation

struct HomeModel {
    var errorMessage: String? = nil
    var todayEstate: Loadable<[TodayEstateWithAddress]> = .idle
    var hotEstate: Loadable<[HotEstateWithAddress]> = .idle
    var topicEstate: Loadable<TopicEstateEntity> = .idle
    var address = AddressResponseEntity(roadAddressName: "", roadRegion1: "", roadRegion2: "", roadRegion3: "")
}
enum HomeIntent {
    case initialRequest
}
@MainActor
final class HomeContainer: ObservableObject {
    @Published var model = HomeModel()
    private let repository: NetworkRepository
    
    init(repository: NetworkRepository) {
        self.repository = repository
    }
    
    func handle(_ intent: HomeIntent) {
        switch intent {
        case .initialRequest:
            Task { await getTodayEstate() }
            Task { await getHotEstate() }
            Task { await getTopicEstate() }
        }
    }

    private func getTodayEstate() async {
        model.todayEstate = .loading
        do {
            let summaries = try await repository.getTodayEstate()
            let result = await AddressMappingHelper.mapTodaySummariesWithAddress(summaries.data, repository: repository)
            
            model.todayEstate = .success(result.estates)
            
            if let firstError = result.errors.first {
                model.errorMessage = (firstError as? NetworkError)?.errorDescription ?? firstError.localizedDescription
            }
        } catch {
            let message = (error as? NetworkError)?.errorDescription ?? error.localizedDescription
            model.todayEstate = .failure(message)
        }
    }
    
    private func getHotEstate() async {
        model.hotEstate = .loading
        do {
            let summaries = try await repository.getHotEstate()
            let result = await AddressMappingHelper.mapHotSummariesWithAddress(summaries.data, repository: repository)
            
            model.hotEstate = .success(result.estates)
            
            if let firstError = result.errors.first {
                model.errorMessage = (firstError as? NetworkError)?.errorDescription ?? firstError.localizedDescription
            }
        } catch {
            let message = (error as? NetworkError)?.errorDescription ?? error.localizedDescription
            model.hotEstate = .failure(message)
        }
    }
    
    private func getTopicEstate() async {
        model.topicEstate = .loading
        do {
            let response = try await repository.getTopicEstate()
            model.topicEstate = .success(response)
        } catch {
            let message = (error as? NetworkError)?.errorDescription ?? error.localizedDescription
            model.topicEstate = .failure(message)
        }
    }
}
