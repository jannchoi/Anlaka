//
//  Address.swift
//  Anlaka
//
//  Created by 최정안 on 5/18/25.
//

import Foundation
struct AddressResponseDTO: Decodable {
    let meta: MetaDTO
    let documents: [DocumentDTO]?

    struct MetaDTO: Decodable {
        let total_count: Int
    }

    struct DocumentDTO: Decodable {
        let road_address: RoadAddressDTO?
        let address: JibunAddressDTO?

        struct RoadAddressDTO: Decodable {
            let address_name: String?
            let region_1depth_name: String?
            let region_2depth_name: String?
            let region_3depth_name: String?
            let road_name: String?
            let underground_yn: String?
            let main_building_no: String?
            let sub_building_no: String?
            let building_name: String?
            let zone_no: String?
        }

        struct JibunAddressDTO: Decodable {
            let address_name: String?
            let region_1depth_name: String?
            let region_2depth_name: String?
            let region_3depth_name: String?
            let mountain_yn: String?
            let main_address_no: String?
            let sub_address_no: String?
        }
    }
}

struct AddressResponseEntity {
    var roadAddressName: String
    var roadRegion1: String
    var roadRegion2: String
    var roadRegion3: String
}
struct RoadRegion3Entity {
    var address: String
}

extension AddressResponseDTO {
    func toEntity() -> AddressResponseEntity {
        guard let document = documents?.first else {
            return AddressResponseEntity(roadAddressName: "", roadRegion1: "", roadRegion2: "", roadRegion3: "")
        }
        
        if let road = document.road_address {
            return AddressResponseEntity(
                roadAddressName: road.address_name ?? "",
                roadRegion1: road.region_1depth_name ?? "",
                roadRegion2: road.region_2depth_name ?? "",
                roadRegion3: road.region_3depth_name ?? ""
            )
        } else if let jibun = document.address {
            return AddressResponseEntity(
                roadAddressName: jibun.address_name ?? "",
                roadRegion1: jibun.region_1depth_name ?? "",
                roadRegion2: jibun.region_2depth_name ?? "",
                roadRegion3: jibun.region_3depth_name ?? ""
            )
        } else {
            return AddressResponseEntity(roadAddressName: "", roadRegion1: "", roadRegion2: "", roadRegion3: "")
        }
    }
    func toRoadRegion3Entity() -> RoadRegion3Entity {
        
        guard let document = documents?.first else {
            return RoadRegion3Entity(address: "")
        }
        if let road = document.road_address {
            return RoadRegion3Entity(address: road.region_3depth_name ?? "")
        } else if let jibun = document.address {
            return RoadRegion3Entity(address: jibun.region_3depth_name ?? "")
        } else { return RoadRegion3Entity(address: "")}
    }
   
}
extension AddressResponseEntity {
     func toShortAddress() -> String {
        if !roadRegion3.isEmpty {
            return roadRegion3
        } else if !roadRegion2.isEmpty {
            return roadRegion2
        } else if !roadRegion1.isEmpty {
            return roadRegion1
        } else {
            return roadAddressName
        }
    }
    func toRoadRegion2() -> String {
        if !roadRegion2.isEmpty {
            return roadRegion2
        } else if !roadRegion3.isEmpty {
            return roadRegion3
        } else if !roadRegion1.isEmpty {
            return roadRegion1
        } else {
            return roadAddressName
        }
    }
}


