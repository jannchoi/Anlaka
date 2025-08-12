import Foundation

struct PostSummaryUseCase {
    private let communityRepository: CommunityNetworkRepository
    private let addressRepository: AddressNetworkRepository
    
    init(communityRepository: CommunityNetworkRepository, addressRepository: AddressNetworkRepository) {
        self.communityRepository = communityRepository
        self.addressRepository = addressRepository
    }
    
    // 위치 기반 게시글 조회 (주소 매핑 실패 시 기본값 제공)
    func getLocationPosts(
        category: String?,
        latitude: Double?,
        longitude: Double?,
        maxDistance: Double?,
        next: String?,
        order: String?
    ) async throws -> PostSummaryPaginationResponseEntity {
        // 1. 네트워크에서 데이터 가져오기
        let response = try await communityRepository.getLocationPost(
            category: category,
            latitude: latitude,
            longitude: longitude,
            maxDistance: maxDistance,
            next: next,
            order: order
        )

        // 2. 주소 매핑 (실패 시 기본값 제공)
        let mappedResult = await AddressMappingHelper.mapPostSummariesWithAddress(response.data)

        // 3. 결과 반환
        return PostSummaryPaginationResponseEntity(
            data: mappedResult.estates,
            next: response.next
        )
    }
    
    // 위치 기반 게시글 조회 (주소 매핑 실패 시 데이터 제외)
    func getLocationPostsExcludeFailed(
        category: String?,
        latitude: Double?,
        longitude: Double?,
        maxDistance: Double?,
        next: String?,
        order: String?
    ) async throws -> PostSummaryPaginationResponseEntity {
        // 1. 네트워크에서 데이터 가져오기
        let response = try await communityRepository.getLocationPost(
            category: category,
            latitude: latitude,
            longitude: longitude,
            maxDistance: maxDistance,
            next: next,
            order: order
        )

        // 2. 주소 매핑 (실패 시 데이터 제외)
        let mappedResult = await AddressMappingHelper.mapPostSummariesWithAddressExcludeFailed(response.data)
        // 3. 결과 반환
        return PostSummaryPaginationResponseEntity(
            data: mappedResult.estates,
            next: response.next
        )
    }
    
    // 제목으로 게시글 검색
    func searchPostsByTitle(_ title: String) async throws -> PostSummaryListResponseEntity {
        // 1. 네트워크에서 데이터 가져오기
        let response = try await communityRepository.searchPostByTitle(title: title)
        
        // 2. 주소 매핑
        let mappedResult = await AddressMappingHelper.mapPostSummariesWithAddress(response.data)
        
        // 3. 결과 반환
        return PostSummaryListResponseEntity(
            data: mappedResult.estates
        )
    }
    
    // 사용자 ID로 게시글 검색
    func searchPostsByUserId(_ userId: String) async throws -> PostSummaryPaginationResponseEntity {
        // 1. 네트워크에서 데이터 가져오기
        let response = try await communityRepository.searchPostByUserId(userId: userId)
        
        // 2. 주소 매핑
        let mappedResult = await AddressMappingHelper.mapPostSummariesWithAddress(response.data)
        
        // 3. 결과 반환
        return PostSummaryPaginationResponseEntity(
            data: mappedResult.estates,
            next: response.next
        )
    }
    
    // 내가 좋아요한 게시글 검색
    func searchPostsByMyLike() async throws -> PostSummaryPaginationResponseEntity {
        // 1. 네트워크에서 데이터 가져오기
        let response = try await communityRepository.searchPostByMyLike()
        
        // 2. 주소 매핑
        let mappedResult = await AddressMappingHelper.mapPostSummariesWithAddress(response.data)
        
        // 3. 결과 반환
        return PostSummaryPaginationResponseEntity(
            data: mappedResult.estates,
            next: response.next
        )
    }
} 
