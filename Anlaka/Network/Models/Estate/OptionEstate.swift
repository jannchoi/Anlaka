//
//  OptionEstate.swift
//  Anlaka
//
//  Created by 최정안 on 5/18/25.
//

import Foundation

struct OptionDTO: Decodable {
    let description: String?
    let refrigerator: Bool?
    let washer: Bool?
    let airConditioner: Bool?
    let closet: Bool?
    let shoeRack: Bool?
    let microwave: Bool?
    let sink: Bool?
    let tv: Bool?

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
        return OptionEntity(
            description: description ?? "알 수 없음",
            refrigerator: refrigerator ?? false,
            washer: washer ?? false,
            airConditioner: airConditioner ?? false,
            closet: closet ?? false,
            shoeRack: shoeRack ?? false,
            microwave: microwave ?? false,
            sink: sink ?? false,
            tv: tv ?? false
        )
    }
}
