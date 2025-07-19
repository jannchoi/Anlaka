//
//  CommunityContainer.swift
//  Anlaka
//
//  Created by 최정안 on 7/18/25.
//

import Foundation
import CoreLocation

struct CommunityModel {
    var posts: Loadable<[AddressMappingResult<PostSummaryResponseWithAddress]> = .idle
    var searchText: String = ""
    var selectedSort: TextResource.Community.Sort = .createdAt
    var selectedCategory: TextResource.Community.Category = .all
    var currentLocation: String = ""
    var currentCoordinate: CLLocationCoordinate2D?
    var nextCursor: String?
    var isLoadingMore: Bool = false
    var allPosts: [AddressMappingResult<PostSummaryResponseWithAddress>] = []
}

enum CommunityIntent {
    case onAppear
    case loadPosts
    case loadMorePosts
    case searchPosts(String)
    case sortPosts(String)
    case filterByCategory(String)
    case navigateToPostDetail(String)
    case locationUpdated(CLLocationCoordinate2D)
}

@MainActor
final class CommunityContainer: ObservableObject {
    @Published var model = CommunityModel()
    private let repository: CommunityNetworkRepositoryImp
    private let locationManager = CLLocationManager()
    
    init(repository: CommunityNetworkRepositoryImp) {
        self.repository = repository
        setupLocationManager()
    }
    
    func handle(_ intent: CommunityIntent) {
        switch intent {
        case .onAppear:
            handleOnAppear()
        case .loadPosts:
            loadPosts()
        case .loadMorePosts:
            loadMorePosts()
        case .searchPosts(let query):
            model.searchText = query
            searchPosts(query)
        case .sortPosts(let sortOption):
            if let sort = TextResource.Community.Sort.allCases.first(where: { $0.text == sortOption }) {
                model.selectedSort = sort
                sortCurrentPosts()
            }
        case .filterByCategory(let category):
            if let categoryEnum = TextResource.Community.Category.allCases.first(where: { $0.text == category }) {
                model.selectedCategory = categoryEnum
                filterCurrentPosts()
            }
        case .navigateToPostDetail(let postId):
            // Navigation logic will be handled by the view
            break
        case .locationUpdated(let coordinate):
            model.currentCoordinate = coordinate
            updateCurrentLocation(coordinate)
            loadPosts()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    private func handleOnAppear() {
        // 1. Get current location
        getCurrentLocation()
        
        // 2. Load posts with current location
        loadPosts()
    }
    
    private func getCurrentLocation() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            // Use default location
            let defaultCoordinate = CLLocationCoordinate2D(
                latitude: 37.6522582058481,
                longitude: 127.045432300312
            )
            handle(.locationUpdated(defaultCoordinate))
        @unknown default:
            break
        }
    }
    
    private func loadPosts() {
        guard let coordinate = model.currentCoordinate else {
            model.posts = .failure("위치 정보를 가져올 수 없습니다.")
            return
        }
        
        model.posts = .loading
        model.nextCursor = nil
        model.allPosts = []
        
        Task {
            do {
                let posts = try await repository.getLocationPost(
                    category: model.selectedCategory.serverValue,
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    maxDistance: 30000,
                    next: nil,
                    order: model.selectedSort.rawValue
                )
                
                // 3. Address mapping
                let mappedPosts = try await AddressMappingHelper.mapPostSummariesWithAddress(
                    posts.data,
                    repository: repository
                )
                
                model.allPosts = mappedPosts
                model.nextCursor = posts.next == "0" ? nil : posts.next
                model.posts = .success(mappedPosts)
            } catch {
                let message = (error as? NetworkError)?.errorDescription ?? error.localizedDescription
                model.posts = .failure(message)
            }
        }
    }
    
    private func loadMorePosts() {
        guard let coordinate = model.currentCoordinate,
              let nextCursor = model.nextCursor,
              !model.isLoadingMore else { return }
        
        model.isLoadingMore = true
        
        Task {
            do {
                let posts = try await repository.getLocationPost(
                    category: model.selectedCategory.serverValue,
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    maxDistance: 30000,
                    next: nextCursor,
                    order: model.selectedSort.rawValue
                )
                
                let mappedPosts = try await AddressMappingHelper.mapPostSummariesWithAddress(
                    posts.data,
                    repository: repository
                )
                
                model.allPosts.append(contentsOf: mappedPosts)
                model.nextCursor = posts.next == "0" ? nil : posts.next
                model.posts = .success(model.allPosts)
                model.isLoadingMore = false
            } catch {
                let message = (error as? NetworkError)?.errorDescription ?? error.localizedDescription
                model.posts = .failure(message)
                model.isLoadingMore = false
            }
        }
    }
    
    private func searchPosts(_ query: String) {
        model.posts = .loading
        
        Task {
            do {
                let posts = try await repository.searchPostByTitle(title: query)
                let mappedPosts = try await AddressMappingHelper.mapPostSummariesWithAddress(
                    posts.data,
                    repository: repository
                )
                model.posts = .success(mappedPosts)
            } catch {
                let message = (error as? NetworkError)?.errorDescription ?? error.localizedDescription
                model.posts = .failure(message)
            }
        }
    }
    
    private func sortCurrentPosts() {
        guard case .success(let posts) = model.posts else { return }
        
        let sortedPosts = posts.sorted { first, second in
            switch model.selectedSort {
            case .createdAt:
                return first.summary.createdAt > second.summary.createdAt
            case .likes:
                return first.summary.likeCount > second.summary.likeCount
            }
        }
        
        model.allPosts = sortedPosts
        model.posts = .success(sortedPosts)
    }
    
    private func filterCurrentPosts() {
        guard case .success(let posts) = model.posts else { return }
        
        if model.selectedCategory == .all {
            // Show all posts
            model.posts = .success(model.allPosts)
        } else {
            // Filter by selected category
            let filteredPosts = model.allPosts.filter { post in
                post.summary.category == model.selectedCategory.text
            }
            model.posts = .success(filteredPosts)
        }
    }
    

    
    private func updateCurrentLocation(_ coordinate: CLLocationCoordinate2D) {
        Task {
            do {
                let address = await AddressMappingHelper.getSingleAddress(
                    longitude: coordinate.longitude,
                    latitude: coordinate.latitude,
                    repository: repository
                )
                await MainActor.run {
                    model.currentLocation = address
                }
            } catch {
                print("Failed to update current location: \(error)")
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension CommunityContainer: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        handle(.locationUpdated(location.coordinate))
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
        // Use default location
        let defaultCoordinate = CLLocationCoordinate2D(
            latitude: 37.6522582058481,
            longitude: 127.045432300312
        )
        handle(.locationUpdated(defaultCoordinate))
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            // Use default location
            let defaultCoordinate = CLLocationCoordinate2D(
                latitude: 37.6522582058481,
                longitude: 127.045432300312
            )
            handle(.locationUpdated(defaultCoordinate))
        default:
            break
        }
    }
}
    
