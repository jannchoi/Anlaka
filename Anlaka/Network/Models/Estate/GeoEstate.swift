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
        .init(data: data.compactMap { $0.toEntity() })
    }
}
extension GeoEstateEntity {
    func toPinInfoList() -> [PinInfo] {
        return data.map { estate in
            PinInfo(
                estateId: estate.estateId, 
                image: estate.thumbnails.first,
                longitude: estate.geolocation.longitude,
                latitude: estate.geolocation.latitude,
                title: estate.title,
                deposit: estate.deposit,
                monthlyRent: estate.monthlyRent
            )
        }
    }
}
