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
    let data: [EstateSummaryEntity]
}

extension HotEstateResponseDTO {
    func toEntity() -> HotEstateEntity {
        .init(data: data.map { $0.toEntity() })
    }
}
