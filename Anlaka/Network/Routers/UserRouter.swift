//
//  UserRouter.swift
//  Anlaka
//
//  Created by 최정안 on 5/12/25.
//

import Foundation
enum UserRouter: AuthorizedTarget {
    case emailValidation(EmailValidationRequestDTO)
    case signUp(SignUpRequestDTO)
    case emailLogin(EmailLoginRequestDTO)
    case kakaoLogin(KakaoLoginRequestDTO)
    case appleLogin(AppleLoginRequestDTO)
    
    var baseURL: URL {
        
        let urlStr = BaseURL.baseV1 + "/users"
        return URL(string: urlStr)!}

    var requiresAuthorization: Bool {
        switch self {
        case .emailValidation:
            return false
        case .signUp:
            return false
        case .emailLogin:
            return false
        case .kakaoLogin:
            return false
        case .appleLogin:
            return false
        }
    }
    var path: String {
        switch self {
        case .emailValidation:
            return "/validation/email"
        case .signUp:
            return "/join"
        case .emailLogin:
            return "/login"
        case .kakaoLogin:
            return "/login/kakao"
        case .appleLogin:
            return "/login/apple"
        }
    }

    var method: String {
        return "POST"
    }

    var header: [String: String] {
        return [
            "SeSACKey": AppConfig.apiKey,
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
