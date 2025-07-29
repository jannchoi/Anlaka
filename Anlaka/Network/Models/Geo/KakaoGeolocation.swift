//
//  KakaoGeolocation.swift
//  Anlaka
//
//  Created by 최정안 on 5/22/25.
//

import Foundation

struct KakaoGeolocationDTO: Decodable {
    let documents: [KakaoDocumentDTO]?
}
struct KakaoDocumentDTO: Decodable {
    let x: String?
    let y: String?
}

extension KakaoGeolocationDTO {
    func toEntity() -> GeolocationEntity {
        guard let document = documents?.first else {
            return GeolocationEntity(longitude: 0.0, latitude: 0.0)
        }
        if let lonStr = document.x, let lon = Double(lonStr), let latStr = document.y, let lat = Double(latStr) {
            return GeolocationEntity(longitude: lon, latitude: lat)
        } else {
            return GeolocationEntity(longitude: 0.0, latitude: 0.0)
        }
        
    }
}
