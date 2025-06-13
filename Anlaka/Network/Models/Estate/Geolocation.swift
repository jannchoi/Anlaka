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
    func toEntity() -> GeolocationEntity? {
        guard let longitude = longitude, let latitude = latitude else {return nil}
        return GeolocationEntity(longitude: longitude, latitude: latitude )
    }
}

