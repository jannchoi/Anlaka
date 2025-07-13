//
//  LoginResponse.swift
//  Anlaka
//
//  Created by 최정안 on 5/13/25.
//

import Foundation

struct LoginResponseDTO: Decodable {
    let userId: String
    let email: String
    let nick: String
    let profileImage: String?
    let accessToken: String
    let refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email, nick, profileImage, accessToken, refreshToken
    }
}
struct LoginResponseEntity: Codable {
    let userId: String
    let email: String
    let nick: String
    let profileImage: String?
    let accessToken: String
    let refreshToken: String
}
extension LoginResponseDTO {
    func toEntity() -> LoginResponseEntity {
        return LoginResponseEntity(
            userId: userId,
            email: email,
            nick: nick,
            profileImage: profileImage,
            accessToken: accessToken,
            refreshToken: refreshToken
        )
    }
}
