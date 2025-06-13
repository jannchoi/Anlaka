//
//  KakaoGeolocation.swift
//  Anlaka
//
//  Created by 최정안 on 5/22/25.
//

import Foundation

// MARK: - DTO

struct KakaoGeolocationDTO: Decodable {
    let meta: KakaoGeolocationMetaDTO
    let documents: [KakaoGeolocationDocumentDTO]
}

struct KakaoGeolocationMetaDTO: Decodable {
    let totalCount: Int
    let pageableCount: Int
    let isEnd: Bool

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case pageableCount = "pageable_count"
        case isEnd = "is_end"
    }
}

struct KakaoGeolocationDocumentDTO: Decodable {
    let addressName: String?
    let x: String?
    let y: String?
    let address: KakaoGeolocationAddressDetailDTO?
    let roadAddress: KakaoGeolocationRoadAddressDTO?

    enum CodingKeys: String, CodingKey {
        case addressName = "address_name"
        case x, y
        case address
        case roadAddress = "road_address"
    }
}

struct KakaoGeolocationAddressDetailDTO: Decodable {
    let addressName: String?
    let x: String?
    let y: String?

    enum CodingKeys: String, CodingKey {
        case addressName = "address_name"
        case x, y
    }
}

struct KakaoGeolocationRoadAddressDTO: Decodable {
    let addressName: String?
    let x: String?
    let y: String?

    enum CodingKeys: String, CodingKey {
        case addressName = "address_name"
        case x, y
    }
}
// MARK: - Entity

struct KakaoGeolocationEntity {
    let meta: KakaoGeolocationMetaEntity
    let documents: [KakaoGeolocationDocumentEntity]
}

struct KakaoGeolocationMetaEntity {
    let totalCount: Int
    let pageableCount: Int
    let isEnd: Bool
}

struct KakaoGeolocationDocumentEntity {
    let addressName: String
    let longitude: Double?
    let latitude: Double?
    let addressDetail: AddressDetailEntity?
    let roadAddress: RoadAddressEntity?
}

struct AddressDetailEntity {
    let addressName: String
    let longitude: Double?
    let latitude: Double?
}

struct RoadAddressEntity {
    let addressName: String
    let longitude: Double?
    let latitude: Double?
}

// MARK: - DTO to Entity

extension KakaoGeolocationDTO {
    func toEntity() -> KakaoGeolocationEntity {

        return KakaoGeolocationEntity(
            meta: meta.toEntity(),
            documents: documents.map { $0.toEntity() }
        )
    }
}

extension KakaoGeolocationMetaDTO {
    func toEntity() -> KakaoGeolocationMetaEntity {
        KakaoGeolocationMetaEntity(
            totalCount: totalCount,
            pageableCount: pageableCount,
            isEnd: isEnd
        )
    }
}

extension KakaoGeolocationDocumentDTO {
    func toEntity() -> KakaoGeolocationDocumentEntity {
        KakaoGeolocationDocumentEntity(
            addressName: addressName ?? "알수없음",
            longitude: Double(x ?? ""),
            latitude: Double(y ?? ""),
            addressDetail: address?.toEntity(),
            roadAddress: roadAddress?.toEntity()
        )
    }
}

extension KakaoGeolocationAddressDetailDTO {
    func toEntity() -> AddressDetailEntity {
        AddressDetailEntity(
            addressName: addressName ?? "알수없음",
            longitude: Double(x ?? ""),
            latitude: Double(y ?? "")
        )
    }
}

extension KakaoGeolocationRoadAddressDTO {
    func toEntity() -> RoadAddressEntity {
        RoadAddressEntity(
            addressName: addressName ?? "알수없음",
            longitude: Double(x ?? ""),
            latitude: Double(y ?? "")
        )
    }
}
extension KakaoGeolocationDocumentEntity {
    func toSearchListData() -> SearchListData? {
        // 좌표 추출 우선순위: AddressDetail → RoadAddress → 자체 좌표
        let resolvedLongitude = addressDetail?.longitude
            ?? roadAddress?.longitude
            ?? longitude

        let resolvedLatitude = addressDetail?.latitude
            ?? roadAddress?.latitude
            ?? latitude

        guard let finalLongitude = resolvedLongitude,
              let finalLatitude = resolvedLatitude else {
            return nil
        }

        let title = addressDetail?.addressName ?? "Unknown Address"
        let subtitle = roadAddress?.addressName ?? ""

        return SearchListData(
            title: title,
            subtitle: subtitle,
            longitude: finalLongitude,
            latitude: finalLatitude
        )
    }
}
