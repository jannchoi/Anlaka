//
//  CommunityContainer.swift
//  Anlaka
//
//  Created by 최정안 on 7/18/25.
//

import Foundation
import CoreLocation
import Combine
import CoreLocation

struct CommunityModel {
    var posts: Loadable<[PostSummaryResponseEntity]> = .idle
    var searchText: String = ""
    var selectedSort: TextResource.Community.Sort = .createdAt
    var selectedCategory: TextResource.Community.Category = .all
    var currentLocation: String = ""
    var currentCoordinate: CLLocationCoordinate2D?
    var nextCursor: String?
    var isLoadingMore: Bool = false
    var allPosts: [PostSummaryResponseEntity] = []
    var isSearchMode: Bool = false // 제목 검색 모드인지 위치 검색 모드인지 구분
    var showSearchAddressView: Bool = false // SearchAddressView 표시 여부
    var searchResults: [PostSummaryResponseEntity] = [] // 검색 결과 원본 저장
    var searchEntityResults: [PostSummaryResponseEntity] = [] // 검색 결과 Entity 원본 저장 (필터링/정렬용)
    
    // 파일 다운로드 관련
    var downloadedFiles: [ServerFileEntity] = []
    var downloadProgress: [String: Double] = [:]
    var downloadStates: [String: FileDownloadProgress.DownloadState] = [:]
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
    case showLocationSearch // 위치 찾기 버튼 클릭
    case locationSelected(CLLocationCoordinate2D, String) // SearchAddressView에서 위치 선택
    case dismissLocationSearch // SearchAddressView 닫기
    case downloadPostFiles([ServerFileEntity]) // 파일 다운로드 시작
}

@MainActor
final class CommunityContainer: NSObject, ObservableObject, LocationServiceDelegate {
    @Published var model = CommunityModel()
    private let useCase: PostSummaryUseCase
    private let locationService: LocationService // DI로 받음
    
    // 파일 다운로드 관련
    private let fileDownloadRepository = FileDownloadRepositoryFactory.createWithAuth()
    private var cancellables = Set<AnyCancellable>()
    private var hasAppeared = false // 중복 호출 방지 플래그 추가
    
    init(repository: CommunityNetworkRepository, useCase: PostSummaryUseCase, locationService: LocationService) {
        self.useCase = useCase
        self.locationService = locationService // DI로 받음
        super.init()
        locationService.delegate = self
    }
    
    func handle(_ intent: CommunityIntent) {
        switch intent {
        case .onAppear:
            guard !hasAppeared else { return }
            hasAppeared = true
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
        case .showLocationSearch:
            model.showSearchAddressView = true
        case .locationSelected(let coordinate, let address):
            model.currentCoordinate = coordinate
            model.currentLocation = address
            model.isSearchMode = false // 위치 검색 모드로 변경
            model.searchResults = [] // 검색 결과 초기화
            model.searchEntityResults = [] // Entity 결과 초기화
            model.showSearchAddressView = false
            loadPosts() // 새로운 위치로 게시물 로드
        case .dismissLocationSearch:
            model.showSearchAddressView = false
        case .downloadPostFiles(let files):
            startFileDownload(for: files)
        }
    }
    
    // MARK: - Private Methods
    
    private func handleOnAppear() {
        // 1. Get current location
        getCurrentLocation()
        // loadPosts() 호출 제거: 위치 획득 후에만 게시글 요청
    }
    
    private func getCurrentLocation() {
        Task {
            print("📍 LocationService: 위치 요청 시작")
            // 위치 권한 요청과 현재 위치 요청을 한 번에 처리
            if let coordinate = await locationService.requestCurrentLocation() {
                print("📍 LocationService: 위치 획득 성공 - \(coordinate.latitude), \(coordinate.longitude)")
                handle(.locationUpdated(coordinate))
            } else {
                print("📍 LocationService: 위치 획득 실패, 기본 좌표 사용")
                // 기본 좌표 사용
                handle(.locationUpdated(LocationService.defaultCoordinate))
            }
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
                let posts = try await useCase.getLocationPosts(
                    category: model.selectedCategory.serverValue,
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    maxDistance: 30000,
                    next: nil,
                    order: model.selectedSort.rawValue
                )
                //print("📍 게시물 로드 성공 - \(posts.data.count)개")
                model.allPosts = posts.data
                model.nextCursor = posts.next == "0" ? nil : posts.next
                model.posts = .success(posts.data)
            } catch {
                let message = (error as? CustomError)?.errorDescription ?? error.localizedDescription
                model.posts = .failure(message)
            }
        }
    }
    
    private func loadMorePosts() {
        // 페이지네이션은 getLocationPost에서만 지원
        guard !model.isSearchMode,
              let coordinate = model.currentCoordinate,
              let nextCursor = model.nextCursor,
              !model.isLoadingMore else { return }
        
        model.isLoadingMore = true
        
        Task {
            do {
                let posts = try await useCase.getLocationPosts(
                    category: model.selectedCategory.serverValue,
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    maxDistance: 30000,
                    next: nextCursor,
                    order: model.selectedSort.rawValue
                )
                
                model.allPosts.append(contentsOf: posts.data)
                model.nextCursor = posts.next == "0" ? nil : posts.next
                model.posts = .success(model.allPosts)
                model.isLoadingMore = false
            } catch {
                let message = (error as? CustomError)?.errorDescription ?? error.localizedDescription
                model.posts = .failure(message)
                model.isLoadingMore = false
            }
        }
    }
    
    private func searchPosts(_ query: String) {
        guard !query.isEmpty else {
            // 검색어가 비어있으면 현재 위치로 다시 로드
            model.isSearchMode = false
            model.searchResults = [] // 검색 결과 초기화
            model.searchEntityResults = [] // Entity 결과 초기화
            loadPosts()
            return
        }
        
        model.posts = .loading
        model.isSearchMode = true // 제목 검색 모드로 변경
        model.nextCursor = nil // 제목 검색은 페이지네이션 지원 안함
        
        Task {
            do {
                let posts = try await useCase.searchPostsByTitle(query)
                model.posts = .success(posts.data)
                model.searchResults = posts.data // 검색 결과 원본 저장
                model.searchEntityResults = posts.data // Entity 원본 저장
            } catch {
                let message = (error as? CustomError)?.errorDescription ?? error.localizedDescription
                model.posts = .failure(message)
            }
        }
    }
    
    private func sortCurrentPosts() {
        // 정렬 변경 시 서버에서 새로 데이터 로드
        if model.isSearchMode {
            // 검색 모드에서는 Entity 레벨에서 정렬
            let sortedEntities = model.searchEntityResults.sorted { first, second in
                switch model.selectedSort {
                case .createdAt:
                    return first.createdAt > second.createdAt
                case .likes:
                    return first.likeCount > second.likeCount
                }
            }
            
            model.posts = .success(sortedEntities)
        } else {
            // 위치 검색 모드에서는 서버에서 새로 로드
            loadPosts()
        }
    }
    
    private func filterCurrentPosts() {
        // 카테고리 변경 시 서버에서 새로 데이터 로드
        if model.isSearchMode {
            // 검색 모드에서는 Entity 레벨에서 필터링
            let filteredEntities: [PostSummaryResponseEntity]
            
            if model.selectedCategory == .all {
                // 전체 카테고리로 변경 시 모든 검색 결과 표시
                filteredEntities = model.searchEntityResults
            } else {
                // 특정 카테고리 선택 시 Entity에서 필터링
                filteredEntities = model.searchEntityResults.filter { entity in
                    entity.category == model.selectedCategory.text
                }
            }
            
            model.posts = .success(filteredEntities)
        } else {
            if model.selectedCategory == .all {
                // 전체 카테고리로 변경 시 현재 위치에서 다시 로드
                loadPosts()
            } else {
                // 특정 카테고리 선택 시 서버에서 필터링된 데이터 로드
                loadPostsWithCategory()
            }
        }
    }
    
    private func loadPostsWithCategory() {
        loadPosts() // 중복 코드 제거 - loadPosts()가 이미 카테고리와 정렬을 고려함
    }
    

    
    private func updateCurrentLocation(_ coordinate: CLLocationCoordinate2D) {
        Task {
            do {
                let address = await AddressMappingHelper.getSingleAddress(
                    longitude: coordinate.longitude,
                    latitude: coordinate.latitude
                )
                await MainActor.run {
                    model.currentLocation = address
                }
            } catch {
                print("Failed to update current location: \(error)")
            }
        }
    }
    
    // MARK: - File Download Methods
    private func startFileDownload(for files: [ServerFileEntity]) {
        let serverPaths = files.map { $0.serverPath }
        
        // 이미 다운로드된 파일들 먼저 표시
        for file in files {
            if fileDownloadRepository.isFileDownloaded(serverPath: file.serverPath) {
                if let downloadedFile = fileDownloadRepository.getDownloadedFile(serverPath: file.serverPath) {
                    if !model.downloadedFiles.contains(where: { $0.serverPath == file.serverPath }) {
                        model.downloadedFiles.append(downloadedFile)
                    }
                }
            }
        }
        
        // 백그라운드에서 다운로드 시작
        fileDownloadRepository.downloadFilesInBackground(from: serverPaths)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progressMap in
                self?.updateDownloadProgress(progressMap)
            }
            .store(in: &cancellables)
    }
    
    private func updateDownloadProgress(_ progressMap: [String: FileDownloadProgress]) {
        for (serverPath, progress) in progressMap {
            model.downloadProgress[serverPath] = progress.progress
            model.downloadStates[serverPath] = progress.state
            
            // 다운로드 완료된 파일 추가
            if progress.state == .downloaded, let downloadedFile = progress.downloadedFile {
                if !model.downloadedFiles.contains(where: { $0.serverPath == serverPath }) {
                    model.downloadedFiles.append(downloadedFile)
                }
            }
        }
    }
    
    // MARK: - File Download Helper Methods
    func getDownloadedFile(for serverPath: String) -> ServerFileEntity? {
        return model.downloadedFiles.first { $0.serverPath == serverPath }
    }
    
    func isFileDownloaded(serverPath: String) -> Bool {
        return model.downloadedFiles.contains { $0.serverPath == serverPath }
    }
    
    func getDownloadProgress(for serverPath: String) -> Double {
        return model.downloadProgress[serverPath] ?? 0.0
    }
    
    func getDownloadState(for serverPath: String) -> FileDownloadProgress.DownloadState {
        return model.downloadStates[serverPath] ?? .notStarted
    }
    
    // MARK: - LocationServiceDelegate
    func locationService(didUpdateLocation coordinate: CLLocationCoordinate2D) {
        handle(.locationUpdated(coordinate))
    }
    func locationService(didFailWithError error: Error) {
        // 기본 좌표 사용
        handle(.locationUpdated(LocationService.defaultCoordinate))
    }
    func locationService(didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            Task {
                if let coordinate = await locationService.requestCurrentLocation() {
                    handle(.locationUpdated(coordinate))
                }
            }
        } else {
            handle(.locationUpdated(LocationService.defaultCoordinate))
        }
    }
}
    

