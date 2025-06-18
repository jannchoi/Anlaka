//
//  HotEstate.swift
//  Anlaka
//
//  Created by 최정안 on 5/18/25.
//

import Foundation

struct HotEstateResponseDTO: Decodable {
    let data: [EstateSummaryDTO]
}

struct HotEstateEntity {
    let data: [HotSummaryEntity]
}

extension HotEstateResponseDTO {
    func toEntity() -> HotEstateEntity {
        return .init(data: data.compactMap{ $0.toHotEntity() })
    }
}

struct HotSummaryEntity {
    let estateId: String
    let category: String
    let title: String
    let thumbnail: String
    let deposit: Double?
    let monthlyRent: Double?
    let geolocation: GeolocationEntity
    let area: Double?
    let likeCount: Int?
}
struct HotSummaryPresentation {
    let estateId: String
    let category: String
    let title: String
    let thumbnail: String
    let deposit: String
    let monthlyRent: String
    let area: String
    let likeCount: String
}
struct HotEstatePresentation  {
    let data : [HotSummaryPresentation]
}
struct HotEstateWithAddress {
    let summary: HotSummaryPresentation
    let address: String // roadRegion3
}
extension HotEstateEntity {
    func toPresentation() -> HotEstatePresentation {
        return .init(data: data.map{$0.toPresentation()})
    }
}
extension HotSummaryEntity {
    func toPresentation () -> HotSummaryPresentation {
        return HotSummaryPresentation(estateId: estateId, category: category, title: title, thumbnail: thumbnail, deposit: PresentationMapper.formatToShortUnitString(deposit), monthlyRent: PresentationMapper.formatToShortUnitString(monthlyRent), area: PresentationMapper.formatArea(area), likeCount: PresentationMapper.formatCount(likeCount))
    }
}
