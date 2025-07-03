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
    
    // Navigation state
    var navigationDestination: HomeRoute? = nil
    var showSafariSheet: Bool = false
    var safariURL: URL? = nil
    var selectedEstateId: IdentifiableString? = nil
}
enum HomeIntent {
    case initialRequest
    case goToDetail(estateId: String)
    case goToCategory(categoryType: CategoryType)
    case goToEstatesAll(type: EstateListType)
    case goToTopicWeb(url: URL)
    case goToSearch
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
            
        case .goToDetail(let estateId):
            model.selectedEstateId = IdentifiableString(id: estateId)
            
        case .goToCategory(let categoryType):
            model.navigationDestination = .category(categoryType: categoryType)
            
        case .goToEstatesAll(let type):
            model.navigationDestination = .estatesAll(type: type)
            
        case .goToTopicWeb(let url):
            // For web URLs, we'll use a sheet presentation with SafariWebView
            model.safariURL = url
            model.showSafariSheet = true
        case .goToSearch:
            model.navigationDestination = .search
        }
    }
    func resetNavigation() {
        model.navigationDestination = nil
    }

    func closeSafariSheet() {
         model.showSafariSheet = false
         model.safariURL = nil
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
            if let netError = error as? NetworkError, netError == .expiredRefreshToken {
                model.todayEstate = .requiresLogin
            } else {
                let message = (error as? NetworkError)?.errorDescription ?? error.localizedDescription
                model.todayEstate = .failure(message)
            }
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
            if let netError = error as? NetworkError, netError == .expiredRefreshToken {
                model.hotEstate = .requiresLogin
            } else {
                let message = (error as? NetworkError)?.errorDescription ?? error.localizedDescription
                model.hotEstate = .failure(message)
            }
        }
    }
    
    private func getTopicEstate() async {
        model.topicEstate = .loading
        do {
            let response = try await repository.getTopicEstate()
            for _ in response.items {
            }
            model.topicEstate = .success(response)
        } catch {
            if let netError = error as? NetworkError, netError == .expiredRefreshToken {
                model.topicEstate = .requiresLogin
            } else {
                let message = (error as? NetworkError)?.errorDescription ?? error.localizedDescription
                model.topicEstate = .failure(message)
            }
        }
    }
}
