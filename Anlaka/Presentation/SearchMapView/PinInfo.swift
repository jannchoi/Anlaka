//
//  PinInfo.swift
//  Anlaka
//
//  Created by 최정안 on 5/24/25.
//

import Foundation

struct PinInfo: Equatable {
    let estateId : String
    let image : String?
    let longitude: Double
    let latitude: Double
    let title: String
    let deposit: Double?
    let monthlyRent: Double?
}
