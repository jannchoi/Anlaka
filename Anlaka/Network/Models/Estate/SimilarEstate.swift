//
//  SimilarEstate.swift
//  Anlaka
//
//  Created by 최정안 on 5/18/25.
//

import Foundation
struct SimilarEstateResponseDTO: Decodable {
    let data: [EstateSummaryDTO]
}

struct SimilarEstateEntity {
    let data: [SimilarSummaryEntity]
}

extension SimilarEstateResponseDTO {
    func toEntity() -> SimilarEstateEntity {
        .init(data: data.map { $0.toSimilarEntity() })
    }
}

struct SimilarSummaryEntity {
    let estateId: String
    let category: String
    let thumbnails: [String]
    let deposit: Double
    let monthlyRent: Double
    let area: Double
    let geolocation: GeolocationEntity
    let isRecommended: Bool
}
