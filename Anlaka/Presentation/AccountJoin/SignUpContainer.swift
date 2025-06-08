//
//  SignUpContainer.swift
//  Anlaka
//
//  Created by 최정안 on 5/12/25.
//

import Foundation

struct SignUpModel {
    var email: String = ""
    var password: String = ""
    var nickname: String = ""
    var phoneNumber: String = ""
    var introduction: String = ""
    var showPassword: Bool = false
    var isLoading: Bool = false
    var errorMessage: String? = nil

    // 유효성 검사
    var isEmailValid: Bool = false
    var isPasswordValid: Bool = false
    var isNicknameValid: Bool = false
    var isEmailValidServer: Bool = false

    // 메시지
    var emailValidationMessage: String = TextResource.Validation.emailInvalid.text
    var passwordValidationMessage: String = TextResource.Validation.passwordInvalid.text
    var nicknameValidationMessage: String = TextResource.Validation.nickInvalid.text

    // 완료 버튼 조건
    var isSignUpButtonEnabled: Bool {
        isEmailValid && isPasswordValid && isNicknameValid && isEmailValidServer
    }

    var goToLoginView: Bool = false
}


enum SignUpIntent {
    case emailChanged(String)
    case passwordChanged(String)
    case nicknameChanged(String)
    case phoneChanged(String)
    case introChanged(String)
    
    case showingPasswordToggle
    case emailValidateButtonTapped
    case SignUpButtonTapped
}
@MainActor
final class SignUpContainer: ObservableObject {
    @Published var model = SignUpModel()
    private let repository: NetworkRepository

    init(repository: NetworkRepository) {
        self.repository = repository
    }

    func handle(_ intent: SignUpIntent) {
        switch intent {
        case .emailChanged(let email):
            model.email = email
            model.isEmailValidServer = false
            validateEmail(email)

        case .passwordChanged(let password):
            model.password = password
            validatePassword(password)

        case .nicknameChanged(let nickname):
            model.nickname = nickname
            validateNickname(nickname)

        case .phoneChanged(let phone):
            model.phoneNumber = phone

        case .introChanged(let intro):
            model.introduction = intro

        case .showingPasswordToggle:
            model.showPassword.toggle()

        case .emailValidateButtonTapped:
            Task {
                await emailValidation()
            }

        case .SignUpButtonTapped:
            Task {
                model.isLoading = true
                await callSignUp()
            }
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

    private func validateNickname(_ nickname: String) {
        if ValidationManager.shared.isValidNick(nickname) {
            model.isNicknameValid = true
            model.nicknameValidationMessage = TextResource.Validation.nickValid.text
        } else {
            model.isNicknameValid = false
            model.nicknameValidationMessage = TextResource.Validation.nickInvalid.text
        }
    }

    private func emailValidation() async {
        let target = EmailValidationRequestEntity(email: model.email)
        do {
            try await repository.validateEmail(targeteEmail: target)
            model.isEmailValidServer = true
        } catch {
            model.isEmailValidServer = false
            model.errorMessage = (error as? NetworkError)?.errorDescription ?? "알 수 없는 에러: \(error.localizedDescription)"
        }
    }

    private func callSignUp() async {
        guard let deviceToken = UserDefaultsManager.shared.getString(forKey: .deviceToken) else { return }
        let target = SignUpRequestEntity(
            email: model.email,
            password: model.password,
            nickname: model.nickname,
            phone: model.phoneNumber,
            intro: model.introduction,
            deviceToken: deviceToken
        )

        do {
            let response = try await repository.signUp(signUpEntity: target)
            model.goToLoginView = true
            model.isLoading = false
        } catch {
            model.errorMessage = (error as? NetworkError)?.errorDescription ?? "알 수 없는 에러: \(error.localizedDescription)"
        }
    }

}
