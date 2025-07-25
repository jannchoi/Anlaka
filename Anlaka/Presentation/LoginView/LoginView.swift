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
    init(di: DIContainer) {
        self.di = di
        _container = StateObject(wrappedValue: di.makeLoginContainer())
    }
    var body: some View {
        NavigationStack {
            VStack {
                Spacer().frame(height: 80)

                Image(systemName: "home")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .padding()

                VStack(spacing: 16) {
                    TextField("Email", text: Binding(
                        get: { container.model.email },
                        set: { container.handle(.emailChanged($0)) }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                    Text(container.model.emailValidationMessage)
                        .font(.caption)
                        .foregroundColor(container.model.isEmailValid ? .green : .red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    
                    SecureField("Password", text: Binding(
                        get: { container.model.password },
                        set: { container.handle(.passwordChanged($0)) }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Text(container.model.passwordValidationMessage)
                        .font(.caption)
                        .foregroundColor(container.model.isPasswordValid ? .green : .red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
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
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    if container.model.isLoading {
                        ProgressView()
                    }
                    HStack(spacing: 35) {
                        Image(systemName: "apple.logo")
                            .padding(.leading, 47)
                        Text("Apple로 로그인")
                            .foregroundStyle(.white)
                    }
                    .overlay {
                        SignInWithAppleButton { request in
                            request.requestedScopes = [.email, .fullName]
                        } onCompletion: { result in
                            container.handle(.handleAppleLogin(result))
                        }.blendMode(.overlay)
                    }
                    Button {
                        container.handle(.handleKakaoLogin)
                    } label: {
                        HStack {
                            Image(systemName: "message.fill")
                                .padding()
                            Text("카카오톡으로 시작하기")
                        }
                    }
                    

                    Button("Create an account") {
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
            .onChange(of: container.model.loginCompleted) { completed in
                if completed {
                    path.append(LoginRoute.home)
                }
            }
            .onChange(of: container.model.goToSignUpView) { go in
                if go {
                    path.append(LoginRoute.signUp)
                }
            }
            .navigationDestination(for: LoginRoute.self) { route in
                switch route {
                case .home:
                    HomeView()

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
    }
}


