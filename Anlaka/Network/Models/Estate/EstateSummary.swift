//
//  EstateSummary.swift
//  Anlaka
//
//  Created by 최정안 on 5/18/25.
//

import Foundation
struct EstateSummaryDTO: Decodable {
    let estateId: String
    let category: String
    let title: String
    let introduction: String
    let thumbnails: [String]
    let deposit: Double
    let monthlyRent: Double
    let builtYear: String
    let area: Double
    let floors: Int
    let geolocation: GeolocationDTO
    let distance: Double?
    let likeCount: Int
    let isSafeEstate: Bool
    let isRecommended: Bool
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case estateId = "estate_id"
        case category, title, introduction, thumbnails
        case deposit, monthlyRent = "monthly_rent"
        case builtYear = "built_year"
        case area, floors, geolocation, distance
        case likeCount = "like_count"
        case isSafeEstate = "is_safe_estate"
        case isRecommended = "is_recommended"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct EstateSummaryEntity {
    let estateId: String
    let category: String
    let title: String
    let introduction: String
    let thumbnails: [String]
    let deposit: Double
    let monthlyRent: Double
    let builtYear: String
    let area: Double
    let floors: Int
    let geolocation: GeolocationEntity
    let distance: Double?
    let likeCount: Int
    let isSafeEstate: Bool
    let isRecommended: Bool
    let createdAt: String
    let updatedAt: String
}

extension EstateSummaryDTO {
    func toEntity() -> EstateSummaryEntity {
        .init(
            estateId: estateId,
            category: category,
            title: title,
            introduction: introduction,
            thumbnails: thumbnails,
            deposit: deposit,
            monthlyRent: monthlyRent,
            builtYear: builtYear,
            area: area,
            floors: floors,
            geolocation: geolocation.toEntity(),
            distance: distance,
            likeCount: likeCount,
            isSafeEstate: isSafeEstate,
            isRecommended: isRecommended,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

}
extension EstateSummaryDTO {
    func toHotEntity() -> HotSummaryEntity {
        return HotSummaryEntity(
            estateId: estateId,
            category: category,
            title: title,
            thumbnail: thumbnails.first ?? "",
            deposit: deposit,
            monthlyRent: monthlyRent,
            geolocation: geolocation.toEntity(),
            area: area,
            likeCount: likeCount
        )
    }

    func toSimilarEntity() -> SimilarSummaryEntity {
        return SimilarSummaryEntity(
            estateId: estateId,
            category: category,
            thumbnail: thumbnails.first ?? "",
            deposit: deposit,
            monthlyRent: monthlyRent,
            area: area,
            geolocation: geolocation.toEntity(),
            isRecommended: isRecommended
        )
    }

    func toTodayEntity() -> TodaySummaryEntity {
        return TodaySummaryEntity(
            estateId: estateId,
            category: category,
            title: title,
            introduction: introduction,
            thumbnail: thumbnails.first ?? "",
            geolocation: geolocation.toEntity()
        )
    }

}
