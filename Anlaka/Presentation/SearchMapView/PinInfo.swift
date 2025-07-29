//
//  PinInfo.swift
//  Anlaka
//
//  Created by 최정안 on 5/24/25.
//

import Foundation
struct PinInfo {
    let estateId : String
    let image : String?
    let longitude: Double
    let latitude: Double
    let title: String
}
extension PinInfo {
    func isEqual(to other: PinInfo) -> Bool {
        return self.estateId == other.estateId
    }
}
