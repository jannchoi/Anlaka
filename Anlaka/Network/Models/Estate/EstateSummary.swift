//
//  EstateSummary.swift
//  Anlaka
//
//  Created by 최정안 on 5/18/25.
//

import Foundation

struct EstateSummaryDTO: Decodable {
    let estateId: String?
    let category: String?
    let title: String?
    let introduction: String?
    let thumbnails: [String]?
    let deposit: Double?
    let monthlyRent: Double?
    let builtYear: String?
    let area: Double?
    let floors: Int?
    let geolocation: GeolocationDTO?
    let distance: Double?
    let likeCount: Int?
    let isSafeEstate: Bool?
    let isRecommended: Bool?
    let createdAt: String?
    let updatedAt: String?

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
    let deposit: Double?
    let monthlyRent: Double?
    let builtYear: String
    let area: Double?
    let floors: Int?
    let geolocation: GeolocationEntity
    let distance: Double?
    let likeCount: Int?
    let isSafeEstate: Bool?
    let isRecommended: Bool?
    let createdAt: String
    let updatedAt: String
}

struct EstateSummaryPresentation {
    let estateId: String
    let category: String
    let title: String
    let introduction: String
    let thumbnails: [String]
    let deposit: String
    let monthlyRent: String
    let builtYear: String
    let area: String
    let floors: String
    let likeCount: String
    let isSafeEstate: String
    let isRecommended: String
}

extension EstateSummaryDTO {
    func toEntity() -> EstateSummaryEntity? {
        guard let estateId = estateId, let geolocation = geolocation, let geoEntity = geolocation.toEntity() else { return nil }
        
        return EstateSummaryEntity(
            estateId: estateId,
            category: category ?? "알 수 없음",
            title: title ?? "알 수 없음",
            introduction: introduction ?? "알 수 없음",
            thumbnails: thumbnails ?? [],
            deposit: deposit,
            monthlyRent: monthlyRent,
            builtYear: builtYear ?? "알 수 없음",
            area: area,
            floors: floors,
            geolocation: geoEntity,
            distance: distance,
            likeCount: likeCount,
            isSafeEstate: isSafeEstate,
            isRecommended: isRecommended,
            createdAt: createdAt ?? "알 수 없음",
            updatedAt: updatedAt ?? "알 수 없음"
        )
    }

    func toHotEntity() -> HotSummaryEntity? {
        guard let estateId = estateId, let geolocation = geolocation, let geoEntity = geolocation.toEntity() else { return nil }
        
        return HotSummaryEntity(
            estateId: estateId,
            category: category ?? "알 수 없음",
            title: title ?? "알 수 없음",
            thumbnail: thumbnails?.first ?? "",
            deposit: deposit,
            monthlyRent: monthlyRent,
            geolocation: geoEntity,
            area: area,
            likeCount: likeCount
        )
    }

    func toSimilarEntity() -> SimilarSummaryEntity? {
        guard let estateId = estateId, let geolocation = geolocation, let geoEntity = geolocation.toEntity() else { return nil }
        
        return SimilarSummaryEntity(
            estateId: estateId,
            category: category ?? "알 수 없음",
            thumbnail: thumbnails?.first ?? "",
            deposit: deposit,
            monthlyRent: monthlyRent,
            area: area,
            geolocation: geoEntity,
            isRecommended: isRecommended ?? false
        )
    }

    func toTodayEntity() -> TodaySummaryEntity? {
        guard let estateId = estateId, let geolocation = geolocation, let geoEntity = geolocation.toEntity() else { return nil }
        
        return TodaySummaryEntity(
            estateId: estateId,
            category: category ?? "알 수 없음",
            title: title ?? "알 수 없음",
            introduction: introduction ?? "알 수 없음",
            thumbnail: thumbnails?.first ?? "",
            geolocation: geoEntity
        )
    }
}

extension EstateSummaryEntity {
    func toPresentationModel() -> EstateSummaryPresentation {
        return EstateSummaryPresentation(
            estateId: estateId,
            category: category,
            title: title,
            introduction: introduction,
            thumbnails: thumbnails,
            deposit: PresentationMapper.formatToShortUnitString(deposit),
            monthlyRent: PresentationMapper.formatToShortUnitString(monthlyRent),
            builtYear: PresentationMapper.formatBuiltYear(builtYear.isEmpty ? nil : builtYear),
            area: PresentationMapper.formatArea(area),
            floors: PresentationMapper.formatFloor(floors),
            likeCount: PresentationMapper.formatCount(likeCount),
            isSafeEstate: PresentationMapper.mapBool(isSafeEstate),
            isRecommended: PresentationMapper.mapBool(isRecommended)
        )
    }
}
