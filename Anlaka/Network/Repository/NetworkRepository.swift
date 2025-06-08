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
}
