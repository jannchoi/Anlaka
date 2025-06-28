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
    case profileImageUpload(Data)
    case searchUser(String)
    
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
        case .getMyProfileInfo:
            return true
        case .getOtherProfileInfo:
            return true
        case .editProfile:
            return true
        case .profileImageUpload:
            return true
        case .searchUser:
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
    var parameters: [String: Any]? {
        switch self {
        case .getOtherProfileInfo(let id):
            return ["id": id]
        case .searchUser(let keyword):
            return ["nick": keyword]
        default:
            return nil
        }
    }

    var header: [String: String] {
        switch self {
        case .getMyProfileInfo, .getOtherProfileInfo, .searchUser, .profileImageUpload, .editProfile:
        guard let accessToken = UserDefaultsManager.shared.getString(forKey: .accessToken) else {return [:]}
        return [
            "SeSACKey": AppConfig.apiKey,
            "Content-Type": "application/json",
            "Authorization" : accessToken
        ]
        default:
            return [
                "SeSACKey": AppConfig.apiKey,
                "Content-Type": "application/json"
            ]
        }
    }

    func multipartFormData(boundary: String) -> Data {
        var body = Data()
        switch self {
        case .profileImageUpload(let image):
            // 이미지 확장자 검증
            let validExtensions = ["jpg", "jpeg", "png"]
            let imageData = image
            
            // 이미지 압축 (1MB 제한, 100x100 크기로 고정)
            let maxSize: Int = 1 * 1024 * 1024 // 1MB
            let targetSize = CGSize(width: 100, height: 100)
            var compressedImageData = imageData
            var compressionQuality: CGFloat = 0.5 // 낮은 품질로 시작
            
            // 100x100 크기로 리사이즈하고 압축
            if let uiImage = UIImage(data: imageData) {
                UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
                uiImage.draw(in: CGRect(origin: .zero, size: targetSize))
                let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                if let resizedImage = resizedImage {
                    // 압축 품질을 낮춰가며 1MB 이하로 만들기
                    while compressionQuality > 0.1 {
                        if let jpegData = resizedImage.jpegData(compressionQuality: compressionQuality) {
                            if jpegData.count <= maxSize {
                                compressedImageData = jpegData
                                break
                            }
                            compressionQuality -= 0.1
                        } else {
                            break
                        }
                    }
                }
            }
            
            // 이미지 데이터의 시그니처를 확인하여 파일 타입 결정
            var mimeType = "image/jpeg"
            var filename = "image.jpg"
            
            // 이미지 시그니처 확인 (첫 4바이트 사용)
            let imageSignature: [UInt8] = Array(compressedImageData.prefix(4))
            
            // PNG 시그니처 확인 (0x89, 0x50, 0x4E, 0x47)
            if imageSignature.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
                mimeType = "image/png"
                filename = "image.png"
            }

            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            // 서버에서 기대하는 필드명: "profile"
            body.append("Content-Disposition: form-data; name=\"profile\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
            body.append(compressedImageData)
            body.append("\r\n".data(using: .utf8)!)

        default:
            break
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }

    func asURLRequest() throws -> URLRequest {
        var url = baseURL.appendingPathComponent(path)
        switch self {
        case .getMyProfileInfo, .getOtherProfileInfo, .searchUser:
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            if case .searchUser(let keyword) = self {
                components?.queryItems = [URLQueryItem(name: "nick", value: keyword)]
            }
            if let composedURL = components?.url {
                url = composedURL
            }
        default:
            break
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        var headers = header
        let boundary = "Boundary-\(UUID().uuidString)"
        if case .profileImageUpload = self {
            headers["Content-Type"] = "multipart/form-data; boundary=\(boundary)"
        }
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        
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
        case .editProfile(let dto):
            request.httpBody = try JSONEncoder().encode(dto)
        case .profileImageUpload:
            request.httpBody = multipartFormData(boundary: boundary)

        default:
            break
        }
        
        return request
    }
}
