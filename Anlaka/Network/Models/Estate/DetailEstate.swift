//
//  DetailEstate.swift
//  Anlaka
//
//  Created by 최정안 on 5/18/25.
//

import Foundation

struct DetailEstateResponseDTO: Decodable {
    let estateId: String?
    let category: String?
    let title: String?
    let introduction: String?
    let reservationPrice: Int?
    let thumbnails: [String]?
    let description: String?
    let deposit: Double?
    let monthlyRent: Double?
    let builtYear: String?
    let maintenanceFee: Double?
    let area: Double?
    let parkingCount: Int?
    let floors: Int?
    let options: OptionDTO?
    let geolocation: GeolocationDTO?
    let creator: UserInfoDTO?
    let isLiked: Bool?
    let isReserved: Bool?
    let likeCount: Int?
    let isSafeEstate: Bool?
    let isRecommended: Bool?
    let comments: [String]?
    let createdAt: String?
    let updatedAt: String?

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

struct DetailEstateEntity: Identifiable {
    let estateId: String
    let category: String
    let title: String
    let introduction: String
    let reservationPrice: Int?
    let thumbnails: [String]
    let description: String
    let deposit: Double?
    let monthlyRent: Double?
    let builtYear: String
    let maintenanceFee: Double?
    let area: Double?
    let parkingCount: Int?
    let floors: Int?
    let options: OptionEntity
    let geolocation: GeolocationEntity?
    let creator: UserInfoEntity
    let isLiked: Bool?
    let isReserved: Bool?
    let likeCount: Int?
    let isSafeEstate: Bool?
    let isRecommended: Bool?
    let comments: [String]
    let createdAt: String
    let updatedAt: String?
    
    var id: String { estateId }
}

struct DetailEstatePresentation: Identifiable {
    let estateId: String
    let category: String
    let title: String
    let introduction: String
    let reservationPrice: String
    let thumbnails: [String]
    let description: String
    let deposit: String
    let monthlyRent: String
    let builtYear: String
    let maintenanceFee: String
    let area: String
    let parkingCount: String
    let floors: String
    let options: OptionEntity
    let creator: UserInfoPresentation
    let isLiked: Bool
    let isReserved: Bool
    let likeCount: String
    let isSafeEstate: Bool
    let isRecommended: Bool
    let comments: [String]
    let updatedAt: String
    
    var id: String { estateId }
}
struct DetailEstateWithAddrerss {
    let detail: DetailEstatePresentation
    let address: String
}
extension DetailEstateResponseDTO {
    func toEntity() -> DetailEstateEntity? {
        guard let estateId = estateId, let creatorEntity = creator?.toEntity() else { return nil }
    
        
        // OptionDTO가 nil인 경우 기본 OptionEntity 생성
        let optionsEntity: OptionEntity
        if let options = options {
            optionsEntity = options.toEntity()
        } else {
            optionsEntity = OptionEntity(
                description: "알 수 없음",
                refrigerator: false,
                washer: false,
                airConditioner: false,
                closet: false,
                shoeRack: false,
                microwave: false,
                sink: false,
                tv: false
            )
        }
        
        return DetailEstateEntity(
            estateId: estateId,
            category: category ?? "알 수 없음",
            title: title ?? "알 수 없음",
            introduction: introduction ?? "알 수 없음",
            reservationPrice: reservationPrice,
            thumbnails: thumbnails ?? [],
            description: description ?? "알 수 없음",
            deposit: deposit,
            monthlyRent: monthlyRent,
            builtYear: builtYear ?? "알 수 없음",
            maintenanceFee: maintenanceFee,
            area: area,
            parkingCount: parkingCount,
            floors: floors,
            options: optionsEntity,
            geolocation: geolocation?.toEntity(),
            creator: creatorEntity,
            isLiked: isLiked,
            isReserved: isReserved,
            likeCount: likeCount,
            isSafeEstate: isSafeEstate,
            isRecommended: isRecommended,
            comments: comments ?? [],
            createdAt: createdAt ?? "알 수 없음",
            updatedAt: updatedAt
        )
    }
}

extension DetailEstateEntity {
    func toPresentationModel() -> DetailEstatePresentation {
        return DetailEstatePresentation(
            estateId: estateId,
            category: category,
            title: title,
            introduction: introduction,
            reservationPrice: PresentationMapper.mapInt(reservationPrice),
            thumbnails: thumbnails,
            description: description,
            deposit: PresentationMapper.formatToShortUnitString(deposit),
            monthlyRent: PresentationMapper.formatToShortUnitString(monthlyRent),
            builtYear: PresentationMapper.formatBuiltYear(builtYear.isEmpty ? nil : builtYear),
            maintenanceFee: PresentationMapper.formatToShortUnitString(maintenanceFee),
            area: PresentationMapper.formatArea(area),
            parkingCount: PresentationMapper.formatCount(parkingCount),
            floors: PresentationMapper.formatFloor(floors),
            options: options,
            creator: creator.toPresentationModel(),
            isLiked: isLiked ?? false,
            isReserved: isReserved ?? false,
            likeCount: PresentationMapper.formatCount(likeCount),
            isSafeEstate: isSafeEstate ?? false,
            isRecommended: isRecommended ?? false,
            comments: comments, updatedAt: updatedAt ?? "알 수 없음"
        )
    }
}
