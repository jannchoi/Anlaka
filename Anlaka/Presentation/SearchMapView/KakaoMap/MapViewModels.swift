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
    let opacity: CGFloat? // 클러스터의 투명도 (0.4 ~ 1.0), nil이면 계산되지 않음
    let maxRadius: Double // 클러스터의 최대 반지름 (미터 단위)
}

enum ClusteringType {
    case hdbscan(zoomLevel: Int)    // 줌 6-15: HDBSCAN 기반
    case fixedGrid(zoomLevel: Int)  // 줌 16+: 100m 격자 기반
}

// MARK: - POI 차분 구조체
struct POIDiff {
    let toAdd: [PinInfo]
    let toRemove: [String] 
    let toUpdate: [PinInfo]
    
    var hasChanges: Bool {
        return !toAdd.isEmpty || !toRemove.isEmpty || !toUpdate.isEmpty
    }
}
