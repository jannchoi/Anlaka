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
    var likeLists: Loadable<[LikeEstateWithAddress]> = .idle
    // Navigation state
    var navigationDestination: HomeRoute? = nil
    var showSafariSheet: Bool = false
    var safariURL: URL? = nil
    var selectedEstateId: IdentifiableString? = nil
    // 초기화 상태 추적
    var isInitialized: Bool = false
}
enum HomeIntent {
    case initialRequest
    case refreshData
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
            // 이미 초기화된 경우 중복 로드 방지
            guard !model.isInitialized else { return }
            
            Task { await getTodayEstate() }
            Task { await getLikeLists() }
            Task { await getHotEstate() }
            Task { await getTopicEstate() }
            
            model.isInitialized = true
            
        case .refreshData:
            // 기존 데이터를 초기화한 후 다시 로드
            model.todayEstate = .idle
            model.hotEstate = .idle
            model.topicEstate = .idle
            model.likeLists = .idle
            
            Task { await getTodayEstate() }
            Task { await getLikeLists() }
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
    
    private func getLikeLists() async {
        model.likeLists = .loading
        do {
            let likeLists = try await repository.getLikeLists(category: nil, next: nil)

            let result = await AddressMappingHelper.mapLikeSummariesWithAddress(likeLists.data)

            model.likeLists = .success(result.estates)

           

        } catch {
            if let netError = error as? CustomError, netError == .expiredRefreshToken {
                model.likeLists = .requiresLogin
            } else {
                let message = (error as? CustomError)?.errorDescription ?? error.localizedDescription
                model.likeLists = .failure(message)
            }
        }
    }
    private func getTodayEstate() async {
        
        model.todayEstate = .loading
        do {
            let summaries = try await repository.getTodayEstate()
            let result = await AddressMappingHelper.mapTodaySummariesWithAddress(summaries.data)
            
            model.todayEstate = .success(result.estates)
            if let firstError = result.errors.first {
                model.errorMessage = (firstError as? CustomError)?.errorDescription ?? firstError.localizedDescription
            }
        } catch {
            if let netError = error as? CustomError, netError == .expiredRefreshToken {
                model.todayEstate = .requiresLogin
            } else {
                let message = (error as? CustomError)?.errorDescription ?? error.localizedDescription
                model.todayEstate = .failure(message)
            }
        }
    }
    
    private func getHotEstate() async {
        model.hotEstate = .loading
        do {
            let summaries = try await repository.getHotEstate()
            let result = await AddressMappingHelper.mapHotSummariesWithAddress(summaries.data)
            
            model.hotEstate = .success(result.estates)
            if let firstError = result.errors.first {
                model.errorMessage = (firstError as? CustomError)?.errorDescription ?? firstError.localizedDescription
            }
        } catch {
            if let netError = error as? CustomError, netError == .expiredRefreshToken {
                model.hotEstate = .requiresLogin
            } else {
                let message = (error as? CustomError)?.errorDescription ?? error.localizedDescription
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
            if let netError = error as? CustomError, netError == .expiredRefreshToken {
                model.topicEstate = .requiresLogin
            } else {
                let message = (error as? CustomError)?.errorDescription ?? error.localizedDescription
                model.topicEstate = .failure(message)
            }
        }
    }
}
