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
    let data: [EstateSummaryEntity]
}

extension SimilarEstateResponseDTO {
    func toEntity() -> SimilarEstateEntity {
        .init(data: data.map { $0.toEntity() })
    }
}
