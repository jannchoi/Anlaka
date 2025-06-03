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
        .init(data: data.map { $0.toHotEntity() })
    }
}

struct HotSummaryEntity {
    let estateId: String
    let category: String
    let title: String
    let thumbnails: [String]
    let deposit: Double
    let monthlyRent: Double
    let geolocation: GeolocationEntity
    let area: Double
    let likeCount: Int
}
struct HotEstateWithAddress {
    let summary: HotSummaryEntity
    let address: String // roadRegion3
}
struct SimilarEstateWithAddress {
    let summary: SimilarSummaryEntity
    let address: String // roadRegion3
}
