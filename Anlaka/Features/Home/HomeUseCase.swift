import Foundation

struct HomeUseCase {
    private let networkRepository: NetworkRepository
    private let addressRepository: AddressNetworkRepository
    
    init(networkRepository: NetworkRepository, addressRepository: AddressNetworkRepository) {
        self.networkRepository = networkRepository
        self.addressRepository = addressRepository
    }
    
    // 오늘의 부동산 조회 (주소 매핑 포함)
    func getTodayEstate() async throws -> [TodayEstateWithAddress] {
        // 1. 네트워크에서 데이터 가져오기
        let response = try await networkRepository.getTodayEstate()
        print("📍 HomeUseCase: 오늘의 부동산 조회 성공 - 매물 수: \(response.data.count)")
        
        // 2. 주소 매핑 (실패 시 기본값 제공)
        let mappedResult = await AddressMappingHelper.mapTodaySummariesWithAddress(response.data)
        print("📍 HomeUseCase: 주소 매핑 후 매물 수: \(mappedResult.estates.count)")
        
        // 3. 결과 반환
        return mappedResult.estates
    }
    
    // 인기 매물 조회 (주소 매핑 포함)
    func getHotEstate() async throws -> [HotEstateWithAddress] {
        // 1. 네트워크에서 데이터 가져오기
        let response = try await networkRepository.getHotEstate()
        print("📍 HomeUseCase: 인기 매물 조회 성공 - 매물 수: \(response.data.count)")
        
        // 2. 주소 매핑 (실패 시 기본값 제공)
        let mappedResult = await AddressMappingHelper.mapHotSummariesWithAddress(response.data)
        print("📍 HomeUseCase: 주소 매핑 후 매물 수: \(mappedResult.estates.count)")
        
        // 3. 결과 반환
        return mappedResult.estates
    }
    
    // 좋아요 매물 조회 (주소 매핑 포함)
    func getLikeLists(category: String?, next: String?) async throws -> [LikeEstateWithAddress] {
        // 1. 네트워크에서 데이터 가져오기
        let response = try await networkRepository.getLikeLists(category: category, next: next)
        print("📍 HomeUseCase: 좋아요 매물 조회 성공 - 매물 수: \(response.data.count)")
        
        // 2. 주소 매핑 (실패 시 기본값 제공)
        let mappedResult = await AddressMappingHelper.mapLikeSummariesWithAddress(response.data)
        print("📍 HomeUseCase: 주소 매핑 후 매물 수: \(mappedResult.estates.count)")
        
        // 3. 결과 반환
        return mappedResult.estates
    }
    
    // 토픽 부동산 조회 (주소 매핑 불필요)
    func getTopicEstate() async throws -> TopicEstateEntity {
        // 1. 네트워크에서 데이터 가져오기
        let response = try await networkRepository.getTopicEstate()
        print("📍 HomeUseCase: 토픽 부동산 조회 성공")
        
        // 2. 결과 반환 (토픽 부동산은 주소 매핑 불필요)
        return response
    }
    
    // 배너 조회 (주소 매핑 불필요)
    func getBanners() async throws -> [BannerResponseEntity] {
        // 1. 네트워크에서 데이터 가져오기
        let response = try await networkRepository.getBanners()
        print("📍 HomeUseCase: 배너 조회 성공 - 배너 수: \(response.data.count)")
        
        // 2. 결과 반환 (배너는 주소 매핑 불필요)
        return response.data
    }
} 