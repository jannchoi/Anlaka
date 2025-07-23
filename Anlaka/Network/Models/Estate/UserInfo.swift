//
//  UserInfo.swift
//  Anlaka
//
//  Created by 최정안 on 5/18/25.
//

import Foundation

struct UserInfoDTO: Decodable {
    let userId: String?
    let nick: String?
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
    let introduction: String
    let profileImage: String
}

struct UserInfoPresentation {
    let userId: String
    let nick: String
    let introduction: String
    let profileImage: String
}

extension UserInfoDTO {
    func toEntity() -> UserInfoEntity? {
        guard let userId = userId else { return nil }
        
        return UserInfoEntity(
            userId: userId,
            nick: nick ?? "알 수 없음",
            introduction: introduction ?? "알 수 없음",
            profileImage: profileImage ?? "알 수 없음"
        )
    }
}

extension UserInfoEntity {
    func toPresentationModel() -> UserInfoPresentation {
        return UserInfoPresentation(
            userId: userId,
            nick: nick,
            introduction: introduction,
            profileImage: profileImage
        )
    }
}
