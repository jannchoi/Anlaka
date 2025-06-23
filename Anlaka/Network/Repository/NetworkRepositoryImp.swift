//
//  NetworkRepositoryImp.swift
//  Anlaka
//
//  Created by 최정안 on 5/12/25.
//

import Foundation

final class NetworkRepositoryImp: NetworkRepository {
    // MARK: - Private Methods
    private func saveTokens(accessToken: String, refreshToken: String) {
        UserDefaultsManager.shared.set(accessToken, forKey: .accessToken)
        UserDefaultsManager.shared.set(refreshToken, forKey: .refreshToken)
        print("🔍 accessToken: \(accessToken)")
    }
    
    private func saveProfileInfo(userId: String, email: String, nick: String, phoneNum: String? = nil, introduction: String? = nil) {
        let profile = MyProfileInfoEntity(
            userid: userId,
            email: email,
            nick: nick,
            profileImage: nil,
            phoneNum: phoneNum,
            introduction: introduction
        )
        UserDefaultsManager.shared.setObject(profile, forKey: .profileData)
    }

    func uploadAdminRequest(adminRequest: AdminRequestMockData) async throws -> DetailEstateEntity {
        do {
            let response = try await NetworkManager.shared.callRequest(target: AdminRouter.uploadAdminRequest(adminRequest), model: DetailEstateResponseDTO.self)
             guard let entity = response.toEntity() else {
                throw CustomError.nilResponse
            }
            return entity
        } catch {
            throw error
        }
    }

    func getMyProfileInfo() async throws -> MyProfileInfoEntity {
        do {
            let response = try await NetworkManager.shared.callRequest(target: UserRouter.getMyProfileInfo, model: MyProfileInfoDTO.self)
            let entity = response.toEntity()
            UserDefaultsManager.shared.setObject(entity, forKey: .profileData)
            return entity
        } catch {
            throw error
        }
    }
    func getChatRooms() async throws -> ChatRoomListEntity {
        //채팅방목록을 가져옴.
        do {
            let response = try await NetworkManager.shared.callRequest(target: ChatRouter.getChatRooms, model: ChatRoomListResponseDTO.self)
            return response.toEntity()
        } catch {
            throw error
        }
    }

    func getChatRoom(opponent_id: String) async throws -> ChatRoomEntity {
        //존재하는 ID라면,채팅방 정보를 가져옴. 존재하지 않는 ID라면 새로운 채팅방을 생성함.
        let target = ChatRoomRequestDTO(opponent_id: opponent_id)
        do {
            let response = try await NetworkManager.shared.callRequest(target: ChatRouter.getChatRoom(target), model: ChatRoomResponseDTO.self)
            return response.toEntity()
        } catch {
            throw error
        }
    }

    func sendMessage(roomId: String, target: ChatRequestEntity) async throws -> ChatEntity {
        //해당 채팅방에 메시지를 보냄.
        let target = target.toDTO()
        do {
            let response = try await NetworkManager.shared.callRequest(target: ChatRouter.sendMessage(roomId: roomId, target), model: ChatResponseDTO.self)
            return response.toEntity()
        } catch {
            throw error
        }
    }

    func getChatList(roomId: String, from: String?) async throws -> ChatListEntity {
        //채팅방의 메시지 목록을 가져옴. from이 존재하는 경우 from으로부터 채팅목록을 가져옴. 존재하지 않는 경우 모든 채팅목록을 가져옴.
        do {
            let response = try await NetworkManager.shared.callRequest(target: ChatRouter.getChatList(roomId: roomId, from: from), model: ChatListResponseDTO.self)
            return response.toEntity()
        } catch {
            throw error
        }
    }
    
    func uploadFiles(roomId: String, files: [ChatFile]) async throws -> ChatFileEntity {
        //파일을 업로드함.
        let target = ChatFilesRequestDTO(files: files)
        do {
            let response = try await NetworkManager.shared.callRequest(target: ChatRouter.uploadFiles(roomId: roomId, target), model: ChatFileResponseDTO.self)
            return response.toEntity()
        } catch {
            throw error
        }
    }

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
            guard let entity = response.toEntity() else {
                throw CustomError.nilResponse
            }
            return entity
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
    
    func getGeoEstate(category: String? = nil, lon: Double, lat: Double, maxD: Double) async throws -> GeoEstateEntity {
        
        do {
            let response = try await NetworkManager.shared.callRequest(
                target: EstateRouter.geoEstate(category: category, lon: String(lon), lat: String(lat), maxD: String(maxD)),
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
            saveProfileInfo(
                userId: entity.userId,
                email: entity.email,
                nick: entity.nick,
                phoneNum: phoneNum,
                introduction: intro
            )
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
            saveTokens(accessToken: entity.accessToken, refreshToken: entity.refreshToken)
        } catch {
            throw error
        }
    }
    func kakaoLogin(kakaoLoginEntity: KakaoLoginRequestEntity) async throws{
        
        let target = kakaoLoginEntity.toDTO()
        do {
            let response = try await NetworkManager.shared.callRequest(target: UserRouter.kakaoLogin(target), model: LoginResponseDTO.self)
            let entity = response.toEntity()
            
            if UserDefaultsManager.shared.getObject(forKey: .profileData, as: MyProfileInfoEntity.self) == nil {
                saveProfileInfo(userId: entity.userId, email: entity.email, nick: entity.nick)
            }
            saveTokens(accessToken: entity.accessToken, refreshToken: entity.refreshToken)
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
            if UserDefaultsManager.shared.getObject(forKey: .profileData, as: MyProfileInfoEntity.self) == nil {
                saveProfileInfo(userId: entity.userId, email: entity.email, nick: entity.nick)
            }
            saveTokens(accessToken: entity.accessToken, refreshToken: entity.refreshToken)
        } catch {
            throw error
        }
    }
}

