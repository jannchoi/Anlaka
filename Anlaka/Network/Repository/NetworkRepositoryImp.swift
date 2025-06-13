//
//  NetworkRepositoryImp.swift
//  Anlaka
//
//  Created by 최정안 on 5/12/25.
//

import Foundation

final class NetworkRepositoryImp: NetworkRepository {
    
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
