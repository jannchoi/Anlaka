//
//  TopicEstate.swift
//  Anlaka
//
//  Created by 최정안 on 5/18/25.
//

import Foundation
struct TopicEstateResponseDTO: Decodable {
    let data: [EstateSummaryDTO]
}

struct TopicEstateEntity {
    let data: [EstateSummaryEntity]
}

extension TopicEstateResponseDTO {
    func toEntity() -> TopicEstateEntity {
        .init(data: data.map { $0.toEntity() })
    }
}
