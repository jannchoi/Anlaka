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
    var toast: FancyToast? = nil

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
            print("🔍 [DEBUG] SignUpButtonTapped 호출됨")
            Task {
                print("🔍 [DEBUG] callSignUp Task 시작")
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
            model.toast = FancyToast(
                type: .success,
                title: "이메일 중복 확인",
                message: "사용 가능한 이메일입니다.",
                duration: 2
            )
        } catch {
            model.isEmailValidServer = false
            model.toast = FancyToast(
                type: .error,
                title: "이메일 중복 확인 실패",
                message: (error as? CustomError)?.errorDescription ?? "이미 사용 중인 이메일입니다.",
                duration: 3
            )
        }
    }

    private func callSignUp() async {
        print("🔍 [DEBUG] callSignUp 함수 시작")
        
        let target = SignUpRequestEntity(
            email: model.email,
            password: model.password,
            nickname: model.nickname,
            phone: model.phoneNumber,
            intro: model.introduction,
            deviceToken: nil
        )
        print("🔍 [DEBUG] SignUpRequestEntity 생성됨: email=\(model.email), nickname=\(model.nickname)")

        do {
            print("🔍 [DEBUG] repository.signUp 호출 시작")
            let response = try await repository.signUp(signUpEntity: target)
            print("✅ [DEBUG] repository.signUp 성공: \(response)")
            
            print("🔍 [DEBUG] 토스트 메시지 설정 시작")
            model.toast = FancyToast(
                type: .success,
                title: "회원가입 완료",
                message: "성공적으로 가입되었습니다.",
                duration: 2
            )
            print("✅ [DEBUG] 토스트 메시지 설정 완료")
            
            model.isLoading = false
            print("🔍 [DEBUG] isLoading = false 설정")
            
            // 토스트 메시지가 표시된 후 2초 뒤에 화면 전환
            print("🔍 [DEBUG] 2초 후 화면 전환 예약")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                print("🔍 [DEBUG] goToLoginView = true 설정")
                self.model.goToLoginView = true
            }
        } catch {
            print("❌ [DEBUG] repository.signUp 실패: \(error)")
            model.toast = FancyToast(
                type: .error,
                title: "회원가입 실패",
                message: (error as? CustomError)?.errorDescription ?? "알 수 없는 에러가 발생했습니다.",
                duration: 3
            )
            model.isLoading = false
        }
    }

}
