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
        .init(data: data.compactMap{ $0.toTodayEntity() })
    }
}

struct TodayEstatePresentation {
    let data: [TodaySummaryPresentation]
}

struct TodaySummaryEntity {
    let estateId: String
    let category: String
    let title: String
    let introduction: String
    let thumbnail: String
    let geolocation: GeolocationEntity

}
struct TodaySummaryPresentation {
    let estateId: String
    let category: String
    let title: String
    let introduction: String
    let thumbnail: String
}
struct TodayEstateWithAddress {
    let summary: TodaySummaryPresentation
    let address: String // roadRegion3
}
extension TodayEstateEntity {
    func toPresentation () -> TodayEstatePresentation {
        return .init(data: data.map{$0.toPresentation()})
    }
}
extension TodaySummaryEntity {
    func toPresentation () -> TodaySummaryPresentation {
        return TodaySummaryPresentation(estateId: estateId, category: category, title: title, introduction: introduction, thumbnail: thumbnail)
    }
}
