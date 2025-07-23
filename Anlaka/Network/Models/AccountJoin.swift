//
//SignUp.swift
//  Anlaka
//
//  Created by 최정안 on 5/12/25.
//

import Foundation
// Request DTO
struct SignUpRequestDTO: Encodable {
    let email: String
    let password: String
    let nick: String
    let phoneNum: String?
    let introduction: String?
    let deviceToken: String?
}

// Response DTO
struct SignUpResponseDTO: Decodable {
    let userId: String
    let email: String
    let nick: String
    let accessToken: String
    let refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email, nick, accessToken, refreshToken
    }
}

// Entity
struct SignUpResponseEntity {
    let userId: String
    let email: String
    let nick: String
    let accessToken: String
    let refreshToken: String
}

struct SignUpRequestEntity {
    let email: String
    let password: String
    let nickname: String
    let phone: String?
    let intro: String?
    let deviceToken: String?
}


// Mapper
extension SignUpResponseDTO {
    func toEntity() -> SignUpResponseEntity {
        return SignUpResponseEntity(
            userId: userId,
            email: email,
            nick: nick,
            accessToken: accessToken,
            refreshToken: refreshToken
        )
    }
}
extension SignUpRequestEntity {
    func toDTO() -> SignUpRequestDTO {
        return SignUpRequestDTO(
            email: email,
            password: password,
            nick: nickname,
            phoneNum: phone,
            introduction: intro,
            deviceToken: deviceToken
        )
    }
}

