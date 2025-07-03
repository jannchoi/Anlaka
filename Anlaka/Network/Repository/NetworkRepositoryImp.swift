//
//  NetworkRepositoryImp.swift
//  Anlaka
//
//  Created by 최정안 on 5/12/25.
//

import Foundation

final class NetworkRepositoryImp: NetworkRepository {
    func getGeoFromKeywordQuery(_ query: String, page: Int) async throws -> KakaoGeoKeywordEntity {
        do {
            let response = try await NetworkManager.shared.callRequest(target: GeoRouter.getGeoByKeyword(query: query, page: page), model: KakaoGeoKeywordDTO.self)
            return response.toEntity()
        } catch {
            throw error
        }
    }
    
    func getGeofromAddressQuery(_ query: String, page: Int) async throws -> KakaoGeolocationEntity {
        do {
            let response = try await NetworkManager.shared.callRequest(target: GeoRouter.getGeolocation(query: query, page: page), model: KakaoGeolocationDTO.self)
            return response.toEntity()
        } catch {
            throw error
        }
    }
    
    func getRoad3FromGeo(_ geo: GeolocationEntity) async throws -> RoadRegion3Entity {
        let (x,y) = (geo.longitude, geo.latitude)
        do {
            let response = try await NetworkManager.shared.callRequest(target: GeoRouter.getAddress(lon: x, lat: y), model: AddressResponseDTO.self)
            return response.toRoadRegion3Entity()
        } catch {
            throw error
        }
    }
    
    func getAddressFromGeo(_ geo: GeolocationEntity) async throws -> AddressResponseEntity {
        let (x,y) = (geo.longitude, geo.latitude)
        do {
            let response = try await NetworkManager.shared.callRequest(target: GeoRouter.getAddress(lon: x, lat: y), model: AddressResponseDTO.self)
            return response.toEntity()
        } catch {
            throw error
        }
    }
    
    
    func getDetailEstate(_ estateId: String) async throws -> DetailEstateEntity {
        do {
            let response = try await NetworkManager.shared.callRequest(
                target: EstateRouter.detailEstate(estateId: estateId),
                model: DetailEstateResponseDTO.self
            )
            return response.toEntity()
        } catch {
            throw error
        }
    }
    
    func postLikeEstate(_ estateId: String, _ targetLikeEstate: LikeEstateEntity) async throws -> LikeEstateEntity {
        let target = targetLikeEstate.toDTO()
        do {
            let response = try await NetworkManager.shared.callRequest(
                target: EstateRouter.likeEstate(estateId: estateId, target),
                model: LikeEstateResponseDTO.self
            )
            return response.toEntity()
        } catch {
            throw error
        }
    }
    
    func getGeoEstate(category: CategoryType?, lon: Double, lat: Double, maxD: Double) async throws -> GeoEstateEntity {
        do {
            let response = try await NetworkManager.shared.callRequest(
                target: EstateRouter.geoEstate(category: category?.rawValue, lon: String(lon), lat: String(lat), maxD: String(maxD)),
                model: GeoEstateResponseDTO.self
            )
            return response.toEntity()
        } catch {
            throw error
        }
    }
    
    func getTodayEstate() async throws -> TodayEstateEntity {
        do {
            let response = try await NetworkManager.shared.callRequest(
                target: EstateRouter.todayEstate,
                model: TodayEstateResponseDTO.self
            )
            return response.toEntity()
        } catch {
            throw error
        }
    }
    
    func getHotEstate() async throws -> HotEstateEntity {
        do {
            let response = try await NetworkManager.shared.callRequest(
                target: EstateRouter.hotEstate,
                model: HotEstateResponseDTO.self
            )
            return response.toEntity()
        } catch {
            throw error
        }
    }
    
    func getSimilarEstate() async throws -> SimilarEstateEntity {
        do {
            let response = try await NetworkManager.shared.callRequest(
                target: EstateRouter.similarEstate,
                model: SimilarEstateResponseDTO.self
            )
            return response.toEntity()
        } catch {
            throw error
        }
    }
    
    func getTopicEstate() async throws -> TopicEstateEntity {
        do {
            let response = try await NetworkManager.shared.callRequest(
                target: EstateRouter.topicEstate,
                model: TopicEstateDTO.self
            )
            return response.toEntity()
        } catch {
            throw error
        }
    }
    
    
    func fetchRefreshToken() async throws -> RefreshTokenEntity {
        do {
            let response = try await NetworkManager.shared.callRequest(
                target: AuthRouter.getRefreshToken,
                model: RefreshTokenResponseDTO.self
            )
            return response.toEntity()
        } catch {
            throw error
        }
    }
    
    func validateEmail(targeteEmail: EmailValidationRequestEntity) async throws {
        let emailValDTO = targeteEmail.toDTO()

        do {
            let response = try await NetworkManager.shared.callRequest(target: UserRouter.emailValidation(emailValDTO), model: EmailValidationResponseDTO.self)
        } catch {
            throw error
        }
    }
    
    func signUp(signUpEntity: SignUpRequestEntity) async throws -> SignUpResponseEntity {
        let target = signUpEntity.toDTO()
        let phoneNum = target.phoneNum
        let intro = target.introduction
        do {
            let response = try await NetworkManager.shared.callRequest(target: UserRouter.signUp(target) , model: SignUpResponseDTO.self)
            let entity = response.toEntity()
            let profile = ProfileInfo(userid: entity.userId, email: entity.email, nick: entity.nick, profileImage: nil, phoneNum: phoneNum, introduction: intro)
            UserDefaultsManager.shared.setObject(profile, forKey: .profileData)
            return response.toEntity()
        }  catch {
            throw error
        }
    }
    func emailLogin(emailLoginEntity: EmailLoginRequestEntity) async throws {
        let target = emailLoginEntity.toDTO()

        do {
            let response = try await NetworkManager.shared.callRequest(target: UserRouter.emailLogin(target), model: LoginResponseDTO.self)
            let entity = response.toEntity()
            UserDefaultsManager.shared.set(entity.accessToken, forKey: .accessToken)
            UserDefaultsManager.shared.set(entity.refreshToken, forKey: .refreshToken)
        } catch {
            throw error
        }
    }
    func kakaoLogin(kakaoLoginEntity: KakaoLoginRequestEntity) async throws{
        let target = kakaoLoginEntity.toDTO()
        do {
            let response = try await NetworkManager.shared.callRequest(target: UserRouter.kakaoLogin(target), model: LoginResponseDTO.self)
            let entity = response.toEntity()
            
            if UserDefaultsManager.shared.getObject(forKey: .profileData, as: ProfileInfo.self) == nil {
                let profile = ProfileInfo(userid: entity.userId, email: entity.email, nick: entity.nick, profileImage: nil, phoneNum: nil, introduction: nil)
                UserDefaultsManager.shared.setObject(profile, forKey: .profileData)
            }
            UserDefaultsManager.shared.set(entity.accessToken, forKey: .accessToken)
            UserDefaultsManager.shared.set(entity.refreshToken, forKey: .refreshToken)
        } catch {
            throw error
        }
    }
    func appleLogin(appleLoginEntity: AppleLoginRequestEntity) async throws {
        let target = appleLoginEntity.toDTO()
        
        do {
            let response = try await NetworkManager.shared.callRequest(
                target: UserRouter.appleLogin(target),
                model: LoginResponseDTO.self
            )
            let entity = response.toEntity()
            if UserDefaultsManager.shared.getObject(forKey: .profileData, as: ProfileInfo.self) == nil {
                let profile = ProfileInfo(userid: entity.userId, email: entity.email, nick: entity.nick, profileImage: nil, phoneNum: nil, introduction: nil)
                UserDefaultsManager.shared.setObject(profile, forKey: .profileData)
            }
            UserDefaultsManager.shared.set(entity.accessToken, forKey: .accessToken)
            UserDefaultsManager.shared.set(entity.refreshToken, forKey: .refreshToken)
        } catch {
            throw error
        }
    }
}
