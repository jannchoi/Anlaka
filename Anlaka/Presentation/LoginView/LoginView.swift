//
//  LoginView.swift
//  Anlaka
//
//  Created by 최정안 on 5/12/25.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    
    let di: DIContainer
    @StateObject private var container: LoginContainer
    @State private var path = NavigationPath()
    @AppStorage(TextResource.Global.isLoggedIn.text) private var isLoggedIn: Bool = true
    init(di: DIContainer) {
        self.di = di
        _container = StateObject(wrappedValue: di.makeLoginContainer())
    }
    var body: some View {
        NavigationStack(path: $path) {
            ZStack{
                Color("WarmLinen")
                    .ignoresSafeArea()
                VStack {
                    Spacer().frame(height: 80)
                    
                    Text("안락한가")
                        .font(.largeTitle)
                        .foregroundStyle(.mainText)
                        .frame(alignment: .center)
                        .padding()
                    
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
                        
                        Button {
                            container.handle(.loginTapped)
                        } label: {
                            if container.model.isLoading {
                                ProgressView()
                            } else {
                                Text("로그인")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .disabled(!container.model.isLoginEnabled)
                        .frame(height: 50)
                        .background(Color.oliveMist)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        
                        if container.model.isLoading {
                            ProgressView()
                        }
                        SignInWithAppleButton { request in
                            request.requestedScopes = [.email, .fullName]
                        } onCompletion: { result in
                            container.handle(.handleAppleLogin(result))
                        }
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(8)
                        Button {
                            container.handle(.handleKakaoLogin)
                        } label: {
                            Image("kakao_login_button")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 50)
                                .frame(maxWidth: .infinity)
                        }
                        .cornerRadius(8)
                        
                        
                        Button("계정 만들기") {
                            container.handle(.signUpButtontTapped)
                        }
                        .foregroundColor(.gray)
                        
                        if let error = container.model.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.footnote)
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                }
            }
            .dismissKeyboardToolbar()
            .onChange(of: container.model.loginCompleted) { completed in
                if completed {
                    // 로그인 완료 시 isLoggedIn true로 변경
                    isLoggedIn = true
                }
            }
            .navigationDestination(for: LoginRoute.self) { route in
                switch route {
                case .signUp:
                    SignUpView(
                        di: di,
                        onComplete: {
                            path.removeLast()
                        }
                    )
                }
            }
        }
        .onAppear {
            container.model.onNavigate = { route in
                path.append(route)
            }

        }
    }
}


