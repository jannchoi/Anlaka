//
//  LikeEstate.swift
//  Anlaka
//
//  Created by 최정안 on 5/18/25.
//

import Foundation

struct LikeEstateRequestDTO: Encodable {
    let likeStatus: Bool

    enum CodingKeys: String, CodingKey {
        case likeStatus = "like_status"
    }
}

struct LikeEstateResponseDTO: Decodable {
    let likeStatus: Bool?

    enum CodingKeys: String, CodingKey {
        case likeStatus = "like_status"
    }
}

struct LikeEstateEntity {
    let likeStatus: Bool
}

extension LikeEstateResponseDTO {
    func toEntity() -> LikeEstateEntity? {
        guard let isLike = likeStatus else {return nil}
        return LikeEstateEntity(likeStatus: isLike)
    }
}

extension LikeEstateEntity {
    func toDTO() -> LikeEstateRequestDTO {
        .init(likeStatus: likeStatus)
    }
}
