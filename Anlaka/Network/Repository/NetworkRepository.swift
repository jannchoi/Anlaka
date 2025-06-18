//
//  NetworkRepository.swift
//  Anlaka
//
//  Created by 최정안 on 5/12/25.
//

import Foundation

protocol NetworkRepository {
    func fetchRefreshToken(refToken: String) async throws -> RefreshTokenEntity
    func validateEmail(targeteEmail: EmailValidationRequestEntity) async throws -> EmailValidationResponseEntity
    func signUp(signUpEntity: SignUpRequestEntity) async throws -> SignUpResponseEntity
    func emailLogin(emailLoginEntity: EmailLoginRequestEntity) async throws -> LoginResponseEntity
    func kakaoLogin(kakaoLoginEntity: KakaoLoginRequestEntity) async throws -> LoginResponseEntity
    func appleLogin(appleLoginEntity: AppleLoginRequestEntity) async throws -> LoginResponseEntity
    
    func getDetailEstate(_ estateId: String) async throws -> DetailEstateEntity
    func postLikeEstate(_ estateId: String, _ targetLikeEstate: LikeEstateEntity) async throws -> LikeEstateEntity
    func getGeoEstate(category: String?, lon: String?, lat: String?, maxD: String?) async throws -> GeoEstateEntity
    func getTodayEstate() async throws -> TodayEstateEntity
    func getHotEstate() async throws -> HotEstateEntity
    func getSimilarEstate() async throws -> SimilarEstateEntity
    func getTopicEstate() async throws -> TopicEstateEntity
    
    func getAddressFromGeo(_ geo: GeolocationEntity) async throws -> AddressResponseEntity
}
