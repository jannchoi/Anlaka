//
//  RefreshToken.swift
//  Anlaka
//
//  Created by 최정안 on 5/12/25.
//

import Foundation
// Response DTO
struct RefreshTokenResponseDTO: Decodable {
    let accessToken: String
    let refreshToken: String
}

// Entity
struct RefreshTokenEntity {
    let accessToken: String
    let refreshToken: String
}

// Mapper
extension RefreshTokenResponseDTO {
    func toEntity() -> RefreshTokenEntity {
        return RefreshTokenEntity(accessToken: accessToken, refreshToken: refreshToken)
    }
}
