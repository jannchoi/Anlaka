//
//  TodayEstate.swift
//  Anlaka
//
//  Created by 최정안 on 5/18/25.
//

import Foundation

struct TodayEstateResponseDTO: Decodable {
    let data: [EstateSummaryDTO]
}

struct TodayEstateEntity {
    let data: [TodaySummaryEntity]
}

extension TodayEstateResponseDTO {
    func toEntity() -> TodayEstateEntity {
        .init(data: data.map { $0.toTodayEntity() })
    }
}


struct TodaySummaryEntity {
    let estateId: String
    let category: String
    let title: String
    let introduction: String
    let thumbnail: String
    let geolocation: GeolocationEntity

}
struct TodayEstateWithAddress {
    let summary: TodaySummaryEntity
    let address: String // roadRegion3
}
