//
//  LoginContainer.swift
//  Anlaka
//
//  Created by 최정안 on 5/12/25.
//

import Foundation
import AuthenticationServices
import KakaoSDKCommon
import KakaoSDKAuth
import KakaoSDKUser

struct LoginModel {
    var email: String = ""
    var password: String = ""
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var loginCompleted: Bool = false
    var goToSignUpView: Bool = false

    var isEmailValid: Bool = false
    var isPasswordValid: Bool = false

    var emailValidationMessage = TextResource.Validation.emailInvalid.text
    var passwordValidationMessage = TextResource.Validation.passwordInvalid.text

    var isLoginEnabled: Bool {
        isEmailValid && isPasswordValid
    }
    var onNavigate: ((LoginRoute) -> Void)?
}

enum LoginIntent {
    case loginTapped
    case signUpButtontTapped
    case emailChanged(String)
    case passwordChanged(String)
    case handleAppleLogin(Result<ASAuthorization,Error>)
    case handleKakaoLogin
}


@MainActor
final class LoginContainer: NSObject, ObservableObject {
    @Published var model = LoginModel()
    
    private let repository: NetworkRepository
    
    init(repository: NetworkRepository) {
        self.repository = repository
    }

    func handle(_ intent: LoginIntent) {
        switch intent {
        case .emailChanged(let email):
            model.email = email
            validateEmail(email)

        case .passwordChanged(let password):
            model.password = password
            validatePassword(password)

        case .loginTapped:
            Task { await emailLogin() }

        case .signUpButtontTapped:
            model.onNavigate?(.signUp)

        case .handleAppleLogin(let result):
            Task { await handleAppleLogin(result) }

        case .handleKakaoLogin:
            Task { await handleKakaoLogin() }
        }
    }
    private func validateEmail(_ email: String) {
        if ValidationManager.shared.isValidEmail(email) {
            model.isEmailValid = true
            model.emailValidationMessage = TextResource.Validation.emailValid.text
        } else {
            model.isEmailValid = false
            model.emailValidationMessage = TextResource.Validation.emailInvalid.text
        }
    }

    private func validatePassword(_ password: String) {
        if ValidationManager.shared.isValidPassword(password) {
            model.isPasswordValid = true
            model.passwordValidationMessage = TextResource.Validation.passwordValid.text
        } else {
            model.isPasswordValid = false
            model.passwordValidationMessage = TextResource.Validation.passwordInvalid.text
        }
    }

    // MARK: - KakaoLogin
    private func handleKakaoLogin() async {
        
        if (UserApi.isKakaoTalkLoginAvailable()) {
            UserApi.shared.loginWithKakaoTalk {(oauthToken, error) in
                if let error = error {
                    Task { @MainActor in
                        self.model.errorMessage = error.localizedDescription
                    }
                    return
                }
                else {
                    guard let oauthToken = oauthToken else {return}
                    UserDefaultsManager.shared.set(oauthToken.accessToken, forKey: .kakaoToken)
                    
                    Task {
                        await self.callKakaoLogin()
                    }
                }
            }
        } else {
            // 카카오톡 앱이 없을 경우 웹 로그인으로 대체
            UserApi.shared.loginWithKakaoAccount {(oauthToken, error) in
                if let error = error {
                    Task { @MainActor in
                        self.model.errorMessage = error.localizedDescription
                    }
                    return
                }
                else {
                    guard let oauthToken = oauthToken else {return}
                    UserDefaultsManager.shared.set(oauthToken.accessToken, forKey: .kakaoToken)
                    
                    Task {
                        await self.callKakaoLogin()
                    }
                }
            }
        }
    }
    private func callKakaoLogin() async {
        print(#function)
        let oauthToken = UserDefaultsManager.shared.getString(forKey: .kakaoToken)
        let deviceToken = UserDefaultsManager.shared.getString(forKey: .deviceToken)
        let target = KakaoLoginRequestEntity(oauthToken: oauthToken, deviceToken: deviceToken)
        do {
            try await repository.kakaoLogin(kakaoLoginEntity: target)
            model.loginCompleted = true
            model.isLoading = false
        } catch {
            if let error = error as? NetworkError {
                model.errorMessage = error.errorDescription
            }
            else {
                model.errorMessage = "알 수 없는 에러: \(error.localizedDescription)"
                
            }
            print(model.errorMessage)
        }
        
    }
    
    // MARK: - AppleLogin
    private func handleAppleLogin(_ result: Result<ASAuthorization, Error>) async {
        print("🧤 애플 로그인 시작, \(result)")
            switch result {
            case .success(let authResults):
                guard let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential else {
                    model.errorMessage = "유효하지 않은 인증 정보입니다."
                    return
                }
                print("🧤 애플 로그인 성공, \(appleIDCredential)")
                guard let idToken = appleIDCredential.identityToken,
                      let tokenString = String(data: idToken, encoding: .utf8) else {
                    model.errorMessage = "토큰 변환 실패"
                    return
                }
                print("🧤 애플 로그인 성공, \(tokenString)")
                let fullName = appleIDCredential.fullName
                let name = (fullName?.familyName ?? "") + (fullName?.givenName ?? "")
                print(name)
                UserDefaultsManager.shared.set(tokenString, forKey: .appleIdToken)
                await callAppleLogin(name)
            case .failure(let error):
                model.errorMessage = "Apple 로그인 실패: \(error.localizedDescription)"
            }
        }
    
    func callAppleLogin(_ nick: String) async {
        print(#function)
        let nickname = nick.isEmpty ? "아무개" : nick
        let idToken = UserDefaultsManager.shared.getString(forKey: .appleIdToken)
        let deviceToken = UserDefaultsManager.shared.getString(forKey: .deviceToken)
        let target = AppleLoginRequestEntity(idToken: idToken, deviceToken: deviceToken, nick: nickname)
        print("🧤 애플 로그인 시작, \(target)")
        do {
            try await repository.appleLogin(appleLoginEntity: target)
            model.loginCompleted = true
            model.isLoading = false
        } catch {
            print("🧤 애플 로그인 실패, \(error)")
            if let error = error as? NetworkError {
                model.errorMessage = error.errorDescription
            } else {
                model.errorMessage = "알 수 없는 에러: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - EmailLogin
    private func emailLogin() async {
        guard model.isLoginEnabled else {
            model.errorMessage = "Please enter email and password"
            return
        }
        let deviceToken = UserDefaultsManager.shared.getString(forKey: .deviceToken)
        model.isLoading = true
        defer { model.isLoading = false }
        
        do {
            let entity = EmailLoginRequestEntity(
                email: model.email,
                password: model.password,
                deviceToken: deviceToken
            )
            try await repository.emailLogin(emailLoginEntity: entity)
            model.loginCompleted = true
            model.isLoading = false
        } catch {
            model.errorMessage = "Login failed: \(error.localizedDescription)"
        }
    }

}
