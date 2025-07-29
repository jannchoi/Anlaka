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
    var banners: Loadable<[BannerResponseEntity]> = .idle
    var likeLists: Loadable<[LikeEstateWithAddress]> = .idle
    // Navigation state
    var navigationDestination: AppRoute.HomeRoute? = nil
    var showSafariSheet: Bool = false
    var safariURL: URL? = nil
    var showBannerWebSheet: Bool = false
    var bannerWebURL: URL? = nil
    var selectedEstateId: IdentifiableString? = nil
    // 초기화 상태 추적
    var isInitialized: Bool = false
    // 캐시 상태 추적
    var isUsingCache: Bool = false
}

enum HomeIntent {
    case initialRequest
    case refreshData
    case goToDetail(estateId: String)
    case goToCategory(categoryType: CategoryType)
    case goToEstatesAll(type: EstateListType)
    case goToTopicWeb(url: URL)
    case goToBannerWeb(url: URL)
    case dismissBannerWeb
    case goToSearch
    case removeFromLikeList(String) // 좋아요 해제된 매물 제거
    case refreshLikeList // 좋아요 매물 리스트 새로고침
}

@MainActor
final class HomeContainer: ObservableObject {
    @Published var model = HomeModel()
    private let useCase: HomeUseCase
    private let tabCache = TabViewCache.shared
    private var estateLikeToggledObserver: NSObjectProtocol? // 매물 좋아요 토글 알림 observer
    
    init(useCase: HomeUseCase) {
        self.useCase = useCase
        
        // 매물 좋아요 토글 알림 구독
        estateLikeToggledObserver = NotificationCenter.default.addObserver(
            forName: .estateLikeToggled,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let (estateId, isLiked) = notification.object as? (String, Bool) {
                if isLiked {
                    // 좋아요 추가된 경우 HomeView에서 새로고침
                    self?.handle(.refreshLikeList)
                } else {
                    // 좋아요 해제된 경우 HomeView에서 제거
                    self?.handle(.removeFromLikeList(estateId))
                }
            }
        }
    }
    
    func handle(_ intent: HomeIntent) {
        switch intent {
        case .initialRequest:
            // 이미 초기화된 경우 중복 로드 방지
            guard !model.isInitialized else { return }
            
            // 캐시된 데이터 확인 후 로드
            loadDataWithCache()
            
            model.isInitialized = true
            
        case .refreshData:
            // 새로고침 시 캐시 무시하고 API 호출
            model.todayEstate = .idle
            model.hotEstate = .idle
            model.topicEstate = .idle
            model.banners = .idle
            model.likeLists = .idle
            model.isUsingCache = false
            
            Task { await getTodayEstate(useCache: false) }
            Task { await getLikeLists(useCache: false) }
            Task { await getHotEstate(useCache: false) }
            Task { await getTopicEstate(useCache: false) }
            Task { await getBanners(useCache: false) }
            
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
        case .goToBannerWeb(let url):
            // For banner web URLs, we'll use a sheet presentation with BannerWebView
            model.bannerWebURL = url
            model.showBannerWebSheet = true
        case .dismissBannerWeb:
            // BannerWebView 닫기
            model.showBannerWebSheet = false
            model.bannerWebURL = nil
        case .goToSearch:
            model.navigationDestination = .search
        case .removeFromLikeList(let estateId):
            removeEstateFromLikeList(estateId: estateId)
        case .refreshLikeList:
            Task { await getLikeLists(useCache: false) }
        }
    }
    
    // MARK: - 캐시 기반 데이터 로드
    
    private func loadDataWithCache() {
        // 캐시된 데이터가 있는지 확인
        let hasCachedData = checkCachedData()
        
        if hasCachedData {
            // 캐시된 데이터 사용
            loadCachedData()
            model.isUsingCache = true
        } else {
            // API 호출
            model.isUsingCache = false
            Task { await getTodayEstate(useCache: false) }
            Task { await getLikeLists(useCache: false) }
            Task { await getHotEstate(useCache: false) }
            Task { await getTopicEstate(useCache: false) }
            Task { await getBanners(useCache: false) }
        }
    }
    
    private func checkCachedData() -> Bool {
        // 각 데이터 타입별로 캐시 확인
        let todayEstateCached = tabCache.getCachedData(for: MyTabView.Tab.home, as: [TodayEstateWithAddress].self) != nil
        let hotEstateCached = tabCache.getCachedData(for: MyTabView.Tab.home, as: [HotEstateWithAddress].self) != nil
        let topicEstateCached = tabCache.getCachedData(for: MyTabView.Tab.home, as: TopicEstateEntity.self) != nil
        let bannersCached = tabCache.getCachedData(for: MyTabView.Tab.home, as: [BannerResponseEntity].self) != nil
        let likeListsCached = tabCache.getCachedData(for: MyTabView.Tab.home, as: [LikeEstateWithAddress].self) != nil
        
        return todayEstateCached || hotEstateCached || topicEstateCached || bannersCached || likeListsCached
    }
    
    private func loadCachedData() {
        // 캐시된 데이터를 모델에 로드
        if let cachedTodayEstate = tabCache.getCachedData(for: MyTabView.Tab.home, as: [TodayEstateWithAddress].self) {
            model.todayEstate = .success(cachedTodayEstate)
        }
        
        if let cachedHotEstate = tabCache.getCachedData(for: MyTabView.Tab.home, as: [HotEstateWithAddress].self) {
            model.hotEstate = .success(cachedHotEstate)
        }
        
        if let cachedTopicEstate = tabCache.getCachedData(for: MyTabView.Tab.home, as: TopicEstateEntity.self) {
            model.topicEstate = .success(cachedTopicEstate)
        }
        
        if let cachedBanners = tabCache.getCachedData(for: MyTabView.Tab.home, as: [BannerResponseEntity].self) {
            model.banners = .success(cachedBanners)
        }
        
        if let cachedLikeLists = tabCache.getCachedData(for: MyTabView.Tab.home, as: [LikeEstateWithAddress].self) {
            model.likeLists = .success(cachedLikeLists)
        }
    }
    
    // MARK: - API 호출 메서드 (캐시 지원)
    
    private func getTodayEstate(useCache: Bool = true) async {
        if useCache {
            // 캐시 확인
            if let cachedData = tabCache.getCachedData(for: MyTabView.Tab.home, as: [TodayEstateWithAddress].self) {
                model.todayEstate = .success(cachedData)
                return
            }
        }
        
        model.todayEstate = .loading
        
        do {
            let response = try await useCase.getTodayEstate()
            model.todayEstate = .success(response)
            
            // 캐시에 저장
            tabCache.setCachedData(response, for: MyTabView.Tab.home)
            
        } catch {
            print("❌ Failed to get today estate: \(error)")
            if let netError = error as? CustomError, netError == .expiredRefreshToken {
                print(" Refresh Token 만료 - 자동 로그아웃 처리")
                handleRefreshTokenExpiration()
            } else {
                let message = (error as? CustomError)?.errorDescription ?? error.localizedDescription
                model.errorMessage = message
                model.todayEstate = .failure(message)
            }
        }
    }
    
    private func getLikeLists(useCache: Bool = true) async {
        if useCache {
            // 캐시 확인
            if let cachedData = tabCache.getCachedData(for: MyTabView.Tab.home, as: [LikeEstateWithAddress].self) {
                model.likeLists = .success(cachedData)
                return
            }
        }
        
        model.likeLists = .loading
        
        do {
            let response = try await useCase.getLikeLists(category: nil, next: nil)
            model.likeLists = .success(response)
            
            // 캐시에 저장
            tabCache.setCachedData(response, for: MyTabView.Tab.home)
            
        } catch {
            print("❌ Failed to get like lists: \(error)")
            if let netError = error as? CustomError, netError == .expiredRefreshToken {
                print(" Refresh Token 만료 - 자동 로그아웃 처리")
                handleRefreshTokenExpiration()
            } else {
                let message = (error as? CustomError)?.errorDescription ?? error.localizedDescription
                model.errorMessage = message
                model.likeLists = .failure(message)
            }
        }
    }
    
    private func getHotEstate(useCache: Bool = true) async {
        if useCache {
            // 캐시 확인
            if let cachedData = tabCache.getCachedData(for: MyTabView.Tab.home, as: [HotEstateWithAddress].self) {
                model.hotEstate = .success(cachedData)
                return
            }
        }
        
        model.hotEstate = .loading
        
        do {
            let response = try await useCase.getHotEstate()
            model.hotEstate = .success(response)
            
            // 캐시에 저장
            tabCache.setCachedData(response, for: MyTabView.Tab.home)

            
        } catch {
            print("❌ Failed to get hot estate: \(error)")
            if let netError = error as? CustomError, netError == .expiredRefreshToken {
                print(" Refresh Token 만료 - 자동 로그아웃 처리")
                handleRefreshTokenExpiration()
            } else {
                let message = (error as? CustomError)?.errorDescription ?? error.localizedDescription
                model.errorMessage = message
                model.hotEstate = .failure(message)
            }
        }
    }
    
    private func getTopicEstate(useCache: Bool = true) async {
        if useCache {
            // 캐시 확인
            if let cachedData = tabCache.getCachedData(for: MyTabView.Tab.home, as: TopicEstateEntity.self) {
                model.topicEstate = .success(cachedData)
                return
            }
        }
        
        model.topicEstate = .loading
        
        do {
            let response = try await useCase.getTopicEstate()
            model.topicEstate = .success(response)
            
            // 캐시에 저장
            tabCache.setCachedData(response, for: MyTabView.Tab.home)

            
        } catch {
            print("❌ Failed to get topic estate: \(error)")
            if let netError = error as? CustomError, netError == .expiredRefreshToken {
                print(" Refresh Token 만료 - 자동 로그아웃 처리")
                handleRefreshTokenExpiration()
            } else {
                let message = (error as? CustomError)?.errorDescription ?? error.localizedDescription
                model.errorMessage = message
                model.topicEstate = .failure(message)
            }
        }
    }
    
    private func getBanners(useCache: Bool = true) async {
        if useCache {
            // 캐시 확인
            if let cachedData = tabCache.getCachedData(for: MyTabView.Tab.home, as: [BannerResponseEntity].self) {
                model.banners = .success(cachedData)
                return
            }
        }
        
        model.banners = .loading
        
        do {
            let response = try await useCase.getBanners()
            model.banners = .success(response)
            
            // 캐시에 저장
            tabCache.setCachedData(response, for: MyTabView.Tab.home)

            
        } catch {
            print("❌ Failed to get banners: \(error)")
            if let netError = error as? CustomError, netError == .expiredRefreshToken {
                print(" Refresh Token 만료 - 자동 로그아웃 처리")
                handleRefreshTokenExpiration()
            } else {
                let message = (error as? CustomError)?.errorDescription ?? error.localizedDescription
                model.errorMessage = message
                model.banners = .failure(message)
            }
        }
    }
    
    // MARK: - RefreshToken 만료 처리
    
    private func handleRefreshTokenExpiration() {
        print(" Refresh Token 만료 - 자동 로그아웃 처리")
        
        // Refresh Token 만료 시에도 디바이스 토큰 무효화 (서버에 빈 문자열 전송)
        Task {
            do {
                let success = try await useCase.invalidateDeviceToken()
                if success {
                    print("Refresh Token 만료 시 디바이스 토큰 무효화 성공")
                } else {
                    print("❌ Refresh Token 만료 시 디바이스 토큰 무효화 실패")
                }
            } catch {
                print("❌ Refresh Token 만료 시 디바이스 토큰 무효화 실패: \(error.localizedDescription)")
            }
        }
        
        // 토큰 및 프로필 데이터 제거
        KeychainManager.shared.remove(forKey: .accessToken)
        KeychainManager.shared.remove(forKey: .refreshToken)
        KeychainManager.shared.remove(forKey: .appleIdToken)
        KeychainManager.shared.remove(forKey: .kakaoToken)
        UserDefaultsManager.shared.removeObject(forKey: .profileData)
        
        // 알림 관련 데이터 초기화
        ChatNotificationCountManager.shared.clearAllCounts()
        TemporaryLastMessageManager.shared.clearAllTemporaryMessages()
        CustomNotificationManager.shared.clearAllNotifications()
        
        // 로그인 상태 변경 (@AppStorage isLoggedIn = false)
        UserDefaults.standard.set(false, forKey: TextResource.Global.isLoggedIn.text)
    }
    
    deinit {
        // observer 제거
        if let observer = estateLikeToggledObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - 좋아요 매물 제거
    
    private func removeEstateFromLikeList(estateId: String) {
        // 현재 좋아요 매물 리스트에서 해당 매물 제거
        if case .success(var likeLists) = model.likeLists {
            likeLists.removeAll { $0.summary.estateId == estateId }
            model.likeLists = .success(likeLists)
        }
    }
    
    // MARK: - 네비게이션 리셋
    
    func resetNavigation() {
        model.navigationDestination = nil
    }
}

