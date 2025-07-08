//
//  LikeLists.swift
//  Anlaka
//
//  Created by 최정안 on 6/19/25.
//

import Foundation

struct LikeListsDTO: Decodable {
    let data : [EstateSummaryDTO]
    let nextCursor : String?
    enum CodingKeys: String, CodingKey {
        case data
        case nextCursor = "next_cursor"
    }
}
struct LikeListsEntity {
    let data: [LikeSummaryEntity]
    let nextCursor: String
}

struct LikeSummaryEntity {
    let estateId: String
    let category: String
    let title: String
    let thumbnail: String
    let deposit: Double?
    let monthlyRent: Double?
    let geolocation: GeolocationEntity
    let area: Double?
    let likeCount: Int?
    let isRecommended: Bool?
}
struct LikeSummaryPresentation {
    let estateId: String
    let category: String
    let title: String
    let thumbnail: String
    let deposit: String
    let monthlyRent: String
    let area: String
    let likeCount: String
    let isRecommended: Bool
}

struct LikeEstateWithAddress {
    let summary: LikeSummaryPresentation
    let address: String
}

extension LikeSummaryEntity {
    func toPresentation () -> LikeSummaryPresentation {
        return LikeSummaryPresentation(estateId: estateId, category: category, title: title, thumbnail: thumbnail, deposit: PresentationMapper.formatToShortUnitString(deposit), monthlyRent: PresentationMapper.formatToShortUnitString(monthlyRent), area: PresentationMapper.formatArea(area), likeCount: PresentationMapper.formatCount(likeCount), isRecommended: isRecommended ?? false)
    }
}
extension LikeListsDTO {
    func toEntity() -> LikeListsEntity? {
        // nextCursor가 nil이면 nil 리턴
        guard let nextCursor = nextCursor else { return nil }
        
        // EstateSummaryDTO 배열을 EstateSummaryEntity 배열로 변환
        // nil인 경우는 제외하고 유효한 엔티티만 포함
        let validEntities = data.compactMap { $0.toLikeListEntity() }
        
        return LikeListsEntity(
            data: validEntities,
            nextCursor: nextCursor
        )
    }
}
