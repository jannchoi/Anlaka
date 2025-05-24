//
//  GeoEstate.swift
//  Anlaka
//
//  Created by 최정안 on 5/18/25.
//

import Foundation

struct GeoEstateResponseDTO: Decodable {
    let data: [EstateSummaryDTO]
}

struct GeoEstateEntity {
    let data: [EstateSummaryEntity]
}

extension GeoEstateResponseDTO {
    func toEntity() -> GeoEstateEntity {
        .init(data: data.map { $0.toEntity() })
    }
}
