//
//  AccountView.swift
//  Anlaka
//
//  Created by 최정안 on 5/12/25.
//

import SwiftUI

struct SignUpView: View {
    let onComplete: () -> Void
    let di: DIContainer
    @StateObject var container: SignUpContainer
    
    init(di: DIContainer, onComplete: @escaping () -> Void = {}) {
        self.di = di
        self.onComplete = onComplete
        _container = StateObject(wrappedValue: di.makeSignUpContainer())
    }
    
    var body: some View {
        VStack(spacing: 0) {
            CustomNavigationBar(title: "회원가입", leftButton:  {
                Button(action: {
                    onComplete()
                }) {
                    Image("chevron")
                        .font(.headline)
                        .foregroundColor(.MainTextColor)
                }
            })
            
            ZStack {
                Color("WarmLinen")
                    .ignoresSafeArea()
                
                ScrollView {
                    SignUpFormView(container: container)
                        .dismissKeyboardToolbar()
                        .padding(20)
                }
            }
        }
        .alert(item: Binding(
            get: { container.model.errorMessage.map { Message(text: $0) } },
            set: { _ in container.model.errorMessage = nil })
        ) { message in
            Alert(title: Text("오류"), message: Text(message.text), dismissButton: .default(Text("확인")))
        }
        .toastView(toast: $container.model.toast)
        .onChange(of: container.model.toast) { toast in
            print("🔍 [DEBUG] 토스트 상태 변경: \(toast?.title ?? "nil")")
        }
        .onChange(of: container.model.goToLoginView) { go in
            print("🔍 [DEBUG] goToLoginView 변경 감지: \(go)")
            if go {
                print("🔍 [DEBUG] onComplete() 호출 시작")
                onComplete()
                print("🔍 [DEBUG] onComplete() 호출 완료")
            }
        }
    }
}

// MARK: - SignUpFormView
private struct SignUpFormView: View {
    @ObservedObject var container: SignUpContainer
    
    var body: some View {
        VStack(spacing: 16) {
            SignUpInputFieldsView(container: container)
            SignUpIntroductionView(container: container)
            SignUpButtonView(container: container)
        }
    }
}

// MARK: - SignUpInputFieldsView
private struct SignUpInputFieldsView: View {
    @ObservedObject var container: SignUpContainer
    
    var body: some View {
        VStack(spacing: 16) {
            CustomTextField(
                title: "이메일",
                text: $container.model.email,
                keyboardType: .emailAddress,
                validationMessage: container.model.emailValidationMessage,
                isValid: container.model.isEmailValid
            )
            .onChange(of: container.model.email) {
                container.handle(.emailChanged($0))
            }
            
            Button(action: {
                container.handle(.emailValidateButtonTapped)
            }) {
                Text("이메일 중복 확인")
                    .font(.pretendardSubheadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(container.model.isEmailValid ? Color.oliveMist : Color.Deselected)
                    .cornerRadius(8)
            }
            .disabled(!container.model.isEmailValid)
            
            CustomTextField(
                title: "비밀번호",
                text: $container.model.password,
                isSecure: true,
                validationMessage: container.model.passwordValidationMessage,
                isValid: container.model.isPasswordValid,
                showsToggleVisibilityButton: true
            )
            .onChange(of: container.model.password) {
                container.handle(.passwordChanged($0))
            }
            
            CustomTextField(
                title: "닉네임",
                text: $container.model.nickname,
                validationMessage: container.model.nicknameValidationMessage,
                isValid: container.model.isNicknameValid
            )
            .onChange(of: container.model.nickname) {
                container.handle(.nicknameChanged($0))
            }
            
            CustomTextField(
                title: "전화번호",
                text: $container.model.phoneNumber,
                keyboardType: .phonePad
            )
            .onChange(of: container.model.phoneNumber) {
                container.handle(.phoneChanged($0))
            }
        }
    }
}

// MARK: - SignUpIntroductionView
private struct SignUpIntroductionView: View {
    @ObservedObject var container: SignUpContainer
    
    // 글자수 계산을 위한 computed properties
    private var characterCount: Int {
        container.model.introduction.count
    }
    
    private var isOverLimit: Bool {
        characterCount > 60
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("자기소개")
                .font(.soyoHeadline)
                .foregroundColor(Color.MainTextColor)
            
            TextEditor(text: Binding(
                get: { container.model.introduction },
                set: { newValue in
                    // 글자수 제한 적용 (공백 포함 60자)
                    let charCount = newValue.count
                    
                    if charCount <= 60 {
                        container.model.introduction = newValue
                        container.handle(.introChanged(newValue))
                    }
                    // 제한을 초과하면 아무것도 하지 않음 (이전 값 유지)
                }
            ))
                .frame(height: 100)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isOverLimit ? Color.TomatoRed : Color.gray.opacity(0.2), lineWidth: 1)
                )
            
            // 글자수 카운터
            HStack {
                Spacer()
                Text("\(characterCount)/60")
                    .font(.pretendardCaption)
                    .foregroundColor(isOverLimit ? Color.TomatoRed : Color.SubText)
            }
        }
    }
}

// MARK: - SignUpButtonView
private struct SignUpButtonView: View {
    @ObservedObject var container: SignUpContainer
    
    var body: some View {
        Button(action: {
            print("🔍 [DEBUG] 완료 버튼 클릭됨")
            print("🔍 [DEBUG] 버튼 활성화 상태: \(container.model.isSignUpButtonEnabled)")
            print("🔍 [DEBUG] 이메일 유효성: \(container.model.isEmailValid)")
            print("🔍 [DEBUG] 비밀번호 유효성: \(container.model.isPasswordValid)")
            print("🔍 [DEBUG] 닉네임 유효성: \(container.model.isNicknameValid)")
            print("🔍 [DEBUG] 이메일 서버 유효성: \(container.model.isEmailValidServer)")
            container.handle(.SignUpButtonTapped)
        }) {
                                    Text("완료")
                            .font(.soyoHeadline)
                            .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(container.model.isSignUpButtonEnabled ? Color.oliveMist : Color.Deselected)
                .cornerRadius(12)
        }
        .disabled(!container.model.isSignUpButtonEnabled)
        .padding(.top, 24)
    }
}

// MARK: - Message
struct Message: Identifiable {
    let id = UUID()
    let text: String
}
