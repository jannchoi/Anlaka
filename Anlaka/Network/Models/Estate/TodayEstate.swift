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
    let data: [EstateSummaryEntity]
}

extension TodayEstateResponseDTO {
    func toEntity() -> TodayEstateEntity {
        .init(data: data.map { $0.toEntity() })
    }
}
