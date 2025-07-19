//
//  UserRouter.swift
//  Anlaka
//
//  Created by 최정안 on 5/12/25.
//

import Foundation
import UIKit

enum UserRouter: AuthorizedTarget {
    case emailValidation(EmailValidationRequestDTO)
    case signUp(SignUpRequestDTO)
    case emailLogin(EmailLoginRequestDTO)
    case kakaoLogin(KakaoLoginRequestDTO)
    case appleLogin(AppleLoginRequestDTO)
    case getMyProfileInfo
    case getOtherProfileInfo(String)
    case editProfile(EditProfileRequestDTO)
    case profileImageUpload(FileData)
    case searchUser(String)
    
    var baseURL: URL {
        let urlStr = BaseURL.baseV1 + "/users"
        return URL(string: urlStr)!
    }

    var requiresAuthorization: Bool {
        switch self {
        case .emailValidation, .signUp, .emailLogin, .kakaoLogin, .appleLogin:
            return false
        default:
            return true
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
        case .getMyProfileInfo:
            return "/me/profile"
        case .getOtherProfileInfo(let id):
            return "/\(id)/profile"
        case .editProfile:
            return "/me/profile"
        case .profileImageUpload:
            return "/profile/image"
        case .searchUser:
            return "/search"
        }
    }

    var method: String {
        switch self {
        case .getMyProfileInfo, .getOtherProfileInfo, .searchUser:
            return "GET"
        case .editProfile:
            return "PUT"
        default:
            return "POST"
        }
    }
    
    var parameters: [String: Any?] {
        switch self {
        case .getOtherProfileInfo(let id):
            return ["id": id]
        case .searchUser(let keyword):
            return ["nick": keyword]
        default:
            return [:]
        }
    }

    var header: [String: String] {
        switch self {
        case .getMyProfileInfo, .getOtherProfileInfo, .searchUser, .profileImageUpload, .editProfile:
            guard let accessToken = UserDefaultsManager.shared.getString(forKey: .accessToken) else { return [:] }
            return [
                "SeSACKey": AppConfig.apiKey,
                "Content-Type": "application/json",
                "Authorization": accessToken
            ]
        default:
            return [
                "SeSACKey": AppConfig.apiKey,
                "Content-Type": "application/json"
            ]
        }
    }
}

// MARK: - UserRouter Specific Implementation
extension UserRouter {
    func multipartFormData(boundary: String) -> Data {
        var body = Data()
        
        switch self {
        case .profileImageUpload(let fileData):
            // 프로필 이미지 업로드 특화 로직
            // 1. 확장자 제한: jpg, png, jpeg
            // 2. 용량 제한: 1MB
            // 3. 최대 파일 개수: 1개
            // 4. request body: multipart/form-data - "profile" : String

            let validExtensions = ["jpg", "jpeg", "png"]
            let maxSize: Int = 1 * 1024 * 1024 // 1MB

            // FileData 타입 활용
            guard validExtensions.contains(fileData.fileExtension.lowercased()) else {
                print("[UserRouter] Invalid file extension: \(fileData.fileExtension)")
                break
            }
            guard fileData.data.count <= maxSize else {
                print("[UserRouter] File too large: \(fileData.fileName)")
                break
            }
            // multipart/form-data 구성
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"profile\"; filename=\"\(fileData.fileName)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(fileData.mimeType)\r\n\r\n".data(using: .utf8)!)
            body.append(fileData.data)
            body.append("\r\n".data(using: .utf8)!)
        default:
            break
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }
    
    func asURLRequest() throws -> URLRequest {
        var url = baseURL.appendingPathComponent(path)
        
        // GET 요청의 경우 쿼리 파라미터 추가
        if method == "GET" {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let queryItems = parameters.map { key, value in
                return URLQueryItem(name: key, value: "\(value)")
            }
            components?.queryItems = queryItems
            if let composedURL = components?.url {
                url = composedURL
            }
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        var headers = header
        let boundary = "Boundary-\(UUID().uuidString)"
        
        // profileImageUpload 케이스일 때 Content-Type 변경
        if case .profileImageUpload = self {
            headers["Content-Type"] = "multipart/form-data; boundary=\(boundary)"
        }
        
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        
        // POST, PUT 요청의 경우 body 추가
        if method == "POST" || method == "PUT" {
            if case .profileImageUpload = self {
                request.httpBody = multipartFormData(boundary: boundary)
            } else {
                // DTO를 직접 인코딩
                let encoder = JSONEncoder()
                switch self {
                case .emailValidation(let dto):
                    request.httpBody = try encoder.encode(dto)
                case .signUp(let dto):
                    request.httpBody = try encoder.encode(dto)
                case .emailLogin(let dto):
                    request.httpBody = try encoder.encode(dto)
                case .kakaoLogin(let dto):
                    request.httpBody = try encoder.encode(dto)
                case .appleLogin(let dto):
                    request.httpBody = try encoder.encode(dto)
                case .editProfile(let dto):
                    request.httpBody = try encoder.encode(dto)
                default:
                    break
                }
            }
        }
        
        return request
    }
}
