//
//  OptionEstate.swift
//  Anlaka
//
//  Created by 최정안 on 5/18/25.
//

import Foundation
struct OptionDTO: Decodable {
    let description: String
    let refrigerator: Bool
    let washer: Bool
    let airConditioner: Bool
    let closet: Bool
    let shoeRack: Bool
    let microwave: Bool
    let sink: Bool
    let tv: Bool

    enum CodingKeys: String, CodingKey {
        case description, refrigerator, washer
        case airConditioner = "air_conditioner"
        case closet, shoeRack = "shoe_rack"
        case microwave, sink, tv
    }
}

struct OptionEntity {
    let description: String
    let refrigerator: Bool
    let washer: Bool
    let airConditioner: Bool
    let closet: Bool
    let shoeRack: Bool
    let microwave: Bool
    let sink: Bool
    let tv: Bool
}

extension OptionDTO {
    func toEntity() -> OptionEntity {
        .init(
            description: description,
            refrigerator: refrigerator,
            washer: washer,
            airConditioner: airConditioner,
            closet: closet,
            shoeRack: shoeRack,
            microwave: microwave,
            sink: sink,
            tv: tv
        )
    }
}
