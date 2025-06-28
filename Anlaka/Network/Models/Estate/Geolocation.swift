//
//  Geolocation.swift
//  Anlaka
//
//  Created by 최정안 on 5/18/25.
//

import Foundation

struct GeolocationDTO: Decodable {
    let longitude: Double?
    let latitude: Double?
}

struct GeolocationEntity {
    let longitude: Double
    let latitude: Double
}

extension GeolocationDTO {
    func toEntity() -> GeolocationEntity {
        GeolocationEntity(longitude: longitude ?? 0.0, latitude: latitude ?? 0.0)
    }
}

extension GeoEstateEntity {
    func toPinInfoList() -> [PinInfo] {
        return data.map { estate in
            PinInfo(
                longitude: estate.geolocation.longitude,
                latitude: estate.geolocation.latitude,
                title: estate.title
            )
        }
    }
}
