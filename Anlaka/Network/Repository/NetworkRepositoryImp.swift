//
//  NetworkRepositoryImp.swift
//  Anlaka
//
//  Created by 최정안 on 5/12/25.
//

import Foundation

final class NetworkRepositoryImp: NetworkRepository {
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
    
    func getGeoEstate(category: String?, lon: String?, lat: String?, maxD: String?) async throws -> GeoEstateEntity {
        do {
            let response = try await NetworkManager.shared.callRequest(
                target: EstateRouter.geoEstate(category: category, lon: lon, lat: lat, maxD: maxD),
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
                model: TopicEstateResponseDTO.self
            )
            return response.toEntity()
        } catch {
            throw error
        }
    }
    
    
    func fetchRefreshToken(refToken: String) async throws -> RefreshTokenEntity {
        do {
            let response = try await NetworkManager.shared.callRequest(
                target: AuthRouter.getRefreshToken(refToken: refToken),
                model: RefreshTokenResponseDTO.self
            )
            return response.toEntity()
        } catch {
            throw error
        }
    }
    
    func validateEmail(targeteEmail: EmailValidationRequestEntity) async throws -> EmailValidationResponseEntity {
        let emailValDTO = targeteEmail.toDTO()

        do {
            let response = try await NetworkManager.shared.callRequest(target: UserRouter.emailValidation(emailValDTO), model: EmailValidationResponseDTO.self)
            return response.toEntity()
        } catch {
            throw error
        }
    }
    
    func signUp(signUpEntity: SignUpRequestEntity) async throws -> SignUpResponseEntity {
        let target = signUpEntity.toDTO()

        do {
            let response = try await NetworkManager.shared.callRequest(target: UserRouter.signUp(target) , model: SignUpResponseDTO.self)
            return response.toEntity()
        }  catch {
            throw error
        }
    }
    func emailLogin(emailLoginEntity: EmailLoginRequestEntity) async throws -> LoginResponseEntity {
        let target = emailLoginEntity.toDTO()

        do {
            let response = try await NetworkManager.shared.callRequest(target: UserRouter.emailLogin(target), model: LoginResponseDTO.self)
            return response.toEntity()
        } catch {
            throw error
        }
    }
    func kakaoLogin(kakaoLoginEntity: KakaoLoginRequestEntity) async throws -> LoginResponseEntity {
        let target = kakaoLoginEntity.toDTO()
        do {
            let response = try await NetworkManager.shared.callRequest(target: UserRouter.kakaoLogin(target), model: LoginResponseDTO.self)
            return response.toEntity()
        } catch {
            throw error
        }
    }
    func appleLogin(appleLoginEntity: AppleLoginRequestEntity) async throws -> LoginResponseEntity {
        let target = appleLoginEntity.toDTO()
        
        do {
            let response = try await NetworkManager.shared.callRequest(
                target: UserRouter.appleLogin(target),
                model: LoginResponseDTO.self
            )
            return response.toEntity()
        } catch {
            throw error
        }
    }
}
