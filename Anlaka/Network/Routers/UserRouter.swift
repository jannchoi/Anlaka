//
//  UserRouter.swift
//  Anlaka
//
//  Created by 최정안 on 5/12/25.
//

import Foundation
enum UserRouter {
    case emailValidation(EmailValidationRequestDTO)
    case signUp(SignUpRequestDTO)
    case emailLogin(EmailLoginRequestDTO)
    case kakaoLogin(KakaoLoginRequestDTO)
    case appleLogin(AppleLoginRequestDTO)
    
    var baseURL: URL { URL(string: BaseURL.baseV1)!}

    var path: String {
        switch self {
        case .emailValidation:
            return "/users/validation/email"
        case .signUp:
            return "/users/join"
        case .emailLogin:
            return "/users/login"
        case .kakaoLogin:
            return "/users/login/kakao"
        case .appleLogin:
            return "/users/login/apple"
        }
    }

    var method: String {
        return "POST"
    }

    var header: [String: String] {
        return [
            "SeSACKey": Environment.apiKey,
            "Content-Type": "application/json"
        ]
    }

    func asURLRequest() throws -> URLRequest {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        header.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        
        switch self {
        case .emailValidation(let dto):
            request.httpBody = try JSONEncoder().encode(dto)
        case .signUp(let dto):
            request.httpBody = try JSONEncoder().encode(dto)
        case .emailLogin(let dto):
            request.httpBody = try JSONEncoder().encode(dto)
        case .kakaoLogin(let dto):
            request.httpBody = try JSONEncoder().encode(dto)
        case .appleLogin(let dto):
            request.httpBody = try JSONEncoder().encode(dto)
        }
        
        return request
    }
}
