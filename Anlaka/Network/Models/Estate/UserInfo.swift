//
//  UserInfo.swift
//  Anlaka
//
//  Created by 최정안 on 5/18/25.
//

import Foundation
struct UserInfoDTO: Decodable {
    let userId: String
    let nick: String
    let introduction: String?
    let profileImage: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case nick, introduction, profileImage
    }
}

struct UserInfoEntity {
    let userId: String
    let nick: String
    let introduction: String?
    let profileImage: String?
}

extension UserInfoDTO {
    func toEntity() -> UserInfoEntity {
        .init(userId: userId, nick: nick, introduction: introduction, profileImage: profileImage)
    }
}
