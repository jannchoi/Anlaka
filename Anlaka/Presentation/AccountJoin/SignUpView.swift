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
            ScrollView {
                VStack(spacing: 16) {
                    Group {
                        CustomTextField(title: "이메일", text: $container.model.email, keyboardType: .emailAddress)
                            .onChange(of: container.model.email) { container.handle(.emailChanged($0)) }

                        Button("이메일 중복 확인") {
                            container.handle(.emailValidateButtonTapped)
                        }
                        .disabled(!container.model.isEmailValid)
                        .font(.subheadline)
                        .foregroundColor(.blue)

                        ZStack(alignment: .trailing) {
                            if container.model.showPassword {
                                CustomTextField(title: "비밀번호", text: $container.model.password, isSecure: false)
                                    .onChange(of: container.model.password) { container.handle(.passwordChanged($0)) }
                            } else {
                                CustomTextField(title: "비밀번호", text: $container.model.password, isSecure: true)
                                    .onChange(of: container.model.password) { container.handle(.passwordChanged($0)) }
                            }

                            Button(action: {
                                container.handle(.showingPasswordToggle)
                            }) {
                                Image(systemName: container.model.showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 12)
                            }
                        }

                        CustomTextField(title: "닉네임", text: $container.model.nickname)
                            .onChange(of: container.model.nickname) { container.handle(.nicknameChanged($0)) }

                        CustomTextField(title: "전화번호", text: $container.model.phoneNumber, keyboardType: .phonePad)
                            .onChange(of: container.model.phoneNumber) { container.handle(.phoneChanged($0)) }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("자기소개")
                            .font(.headline)
                        TextEditor(text: $container.model.introduction)
                            .onChange(of: container.model.introduction) { container.handle(.introChanged($0)) }
                            .frame(height: 100)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }

                    Button(action: {
                        container.handle(.SignUpButtonTapped)
                    }) {
                        Text("완료")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(container.model.isSignUpButtonEnabled ? Color.blue : Color.gray)
                            .cornerRadius(12)
                    }
                    .disabled(!container.model.isSignUpButtonEnabled)
                    .padding(.top, 24)
                }
                .dismissKeyboardToolbar()
                .padding(20)
            }
            .navigationTitle("회원가입")
            .alert(item: Binding(
                get: { container.model.errorMessage.map { Message(text: $0) } },
                set: { _ in container.model.errorMessage = nil })
            ) { message in
                Alert(title: Text("오류"), message: Text(message.text), dismissButton: .default(Text("확인")))
            }
            .onChange(of: container.model.goToLoginView) { go in
                if go {
                    onComplete()
                }
            }
            .onAppear {
                print("signupView 🥶🥶🥶")
            }
        
    }

    struct Message: Identifiable {
        let id = UUID()
        let text: String
    }
}

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)

            Group {
                if isSecure {
                    SecureField("입력하세요", text: $text)
                } else {
                    TextField("입력하세요", text: $text)
                        .keyboardType(keyboardType)
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }
}
