//
//  NetworkRepository.swift
//  Anlaka
//
//  Created by 최정안 on 5/12/25.
//

import Foundation

protocol NetworkRepository {
    func fetchRefreshToken() async throws -> RefreshTokenEntity
    func validateEmail(targeteEmail: EmailValidationRequestEntity) async throws 
    func signUp(signUpEntity: SignUpRequestEntity) async throws -> SignUpResponseEntity
    func emailLogin(emailLoginEntity: EmailLoginRequestEntity) async throws
    func kakaoLogin(kakaoLoginEntity: KakaoLoginRequestEntity) async throws
    func appleLogin(appleLoginEntity: AppleLoginRequestEntity) async throws
    
    func getDetailEstate(_ estateId: String) async throws -> DetailEstateEntity
    func postLikeEstate(_ estateId: String, _ targetLikeEstate: LikeEstateEntity) async throws -> LikeEstateEntity
    func getGeoEstate(category: String?, lon: Double, lat: Double, maxD: Double) async throws -> GeoEstateEntity
    func getTodayEstate() async throws -> TodayEstateEntity
    func getHotEstate() async throws -> HotEstateEntity
    func getSimilarEstate() async throws -> SimilarEstateEntity
    func getTopicEstate() async throws -> TopicEstateEntity
    
    func getAddressFromGeo(_ geo: GeolocationEntity) async throws -> AddressResponseEntity
    func getRoad3FromGeo(_ geo: GeolocationEntity) async throws -> RoadRegion3Entity
    func getGeofromAddressQuery(_ query: String, page: Int) async throws -> KakaoGeolocationEntity
    func getGeoFromKeywordQuery(_ query: String, page: Int) async throws -> KakaoGeoKeywordEntity

    func getChatRooms() async throws -> ChatRoomListEntity
    func getChatRoom(opponent_id: String) async throws -> ChatRoomEntity
    func sendMessage(roomId: String, target: ChatRequestEntity) async throws -> ChatEntity
    func uploadFiles(roomId: String, files: [ChatFile]) async throws -> ChatFileEntity
    func getChatList(roomId: String, from: String?) async throws -> ChatListEntity
    func getMyProfileInfo() async throws -> MyProfileInfoEntity

    func uploadAdminRequest(adminRequest: AdminRequestMockData) async throws -> DetailEstateEntity

    func createOrder(order: CreateOrderRequestDTO) async throws -> CreateOrderEntity
    func getOrders() async throws -> GetOrdersResponseEntity
    func validatePayment(payment: ReceiptPaymentRequestDTO) async throws -> ReceiptOrderResponseEntity
    func getPayment(orderCode: String) async throws -> PaymentResponseEntity
}
