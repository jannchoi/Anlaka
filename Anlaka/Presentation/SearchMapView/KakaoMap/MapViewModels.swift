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
    case zoomLevel6to14
    case zoomLevel15Plus
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
