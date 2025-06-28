//
//  DetailEstate.swift
//  Anlaka
//
//  Created by 최정안 on 5/18/25.
//

import Foundation

struct DetailEstateResponseDTO: Decodable {
    let estateId: String
    let category: String
    let title: String
    let introduction: String
    let reservationPrice: Int
    let thumbnails: [String]
    let description: String
    let deposit: Double
    let monthlyRent: Double
    let builtYear: String
    let maintenanceFee: Double
    let area: Double
    let parkingCount: Int
    let floors: Int
    let options: OptionDTO
    let geolocation: GeolocationDTO
    let creator: UserInfoDTO
    let isLiked: Bool
    let isReserved: Bool
    let likeCount: Int
    let isSafeEstate: Bool
    let isRecommended: Bool
    let comments: [String] // 단순화
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case estateId = "estate_id"
        case category, title, introduction
        case reservationPrice = "reservation_price"
        case thumbnails, description, deposit
        case monthlyRent = "monthly_rent"
        case builtYear = "built_year"
        case maintenanceFee = "maintenance_fee"
        case area, parkingCount = "parking_count", floors
        case options, geolocation, creator
        case isLiked = "is_liked"
        case isReserved = "is_reserved"
        case likeCount = "like_count"
        case isSafeEstate = "is_safe_estate"
        case isRecommended = "is_recommended"
        case comments, createdAt, updatedAt
    }
}

struct DetailEstateEntity {
    let estateId: String
    let category: String
    let title: String
    let introduction: String
    let reservationPrice: Int
    let thumbnails: [String]
    let description: String
    let deposit: Double
    let monthlyRent: Double
    let builtYear: String
    let maintenanceFee: Double
    let area: Double
    let parkingCount: Int
    let floors: Int
    let options: OptionEntity
    let geolocation: GeolocationEntity
    let creator: UserInfoEntity
    let isLiked: Bool
    let isReserved: Bool
    let likeCount: Int
    let isSafeEstate: Bool
    let isRecommended: Bool
    let comments: [String]
    let createdAt: String
    let updatedAt: String
}

extension DetailEstateResponseDTO {
    func toEntity() -> DetailEstateEntity {
        .init(
            estateId: estateId,
            category: category,
            title: title,
            introduction: introduction,
            reservationPrice: reservationPrice,
            thumbnails: thumbnails,
            description: description,
            deposit: deposit,
            monthlyRent: monthlyRent,
            builtYear: builtYear,
            maintenanceFee: maintenanceFee,
            area: area,
            parkingCount: parkingCount,
            floors: floors,
            options: options.toEntity(),
            geolocation: geolocation.toEntity(),
            creator: creator.toEntity(),
            isLiked: isLiked,
            isReserved: isReserved,
            likeCount: likeCount,
            isSafeEstate: isSafeEstate,
            isRecommended: isRecommended,
            comments: comments,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
