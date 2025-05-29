//
//  MapViewModels.swift
//  Anlaka
//
//  Created by 최정안 on 5/31/25.
//

import Foundation
import CoreLocation
struct ClusterInfo {
    let estateIds: [String]
    let centerCoordinate: CLLocationCoordinate2D
    let count: Int
    let representativeImage: String?
}

enum ClusteringType {
    case zoomLevel6to14(radius: Double)  // 원형 + 숫자
    case zoomLevel15to16(radius: Double)     // 대표 이미지 + 배지
    case zoomLevel17Plus                 // 개별 매물
}

// MARK: - POI 차분 구조체
struct POIDiff {
    let toAdd: [PinInfo]
    let toRemove: [String]  // estateId들
    let toUpdate: [PinInfo]
    
    var hasChanges: Bool {
        return !toAdd.isEmpty || !toRemove.isEmpty || !toUpdate.isEmpty
    }
}
