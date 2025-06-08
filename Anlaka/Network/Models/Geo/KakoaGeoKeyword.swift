//
//  KakoaGeoKeyword.swift
//  Anlaka
//
//  Created by 최정안 on 6/3/25.
//

import Foundation

// MARK: - DTO

struct KakaoGeoKeywordDTO: Decodable {
    let meta: KakaoGeoKeywordMetaDTO
    let documents: [KakaoGeoKeywordDocumentDTO]
}

struct KakaoGeoKeywordMetaDTO: Decodable {
    let totalCount: Int
    let pageableCount: Int
    let isEnd: Bool

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case pageableCount = "pageable_count"
        case isEnd = "is_end"
    }
}

struct KakaoGeoKeywordDocumentDTO: Decodable {
    let id: String
    let placeName: String?
    let addressName: String?
    let roadAddressName: String?
    let x: String?
    let y: String?

    enum CodingKeys: String, CodingKey {
        case id
        case placeName = "place_name"
        case addressName = "address_name"
        case roadAddressName = "road_address_name"
        case x, y

    }
}
// MARK: - Entity

struct KakaoGeoKeywordEntity {
    let meta: KakaoGeoKeywordMetaEntity
    let places: [KakaoGeoKeywordPlaceEntity]
}

struct KakaoGeoKeywordMetaEntity {
    let totalCount: Int
    let pageableCount: Int
    let isEnd: Bool
}

struct KakaoGeoKeywordPlaceEntity {
    let id: String
    let name: String
    let address: String
    let roadAddress: String
    let longitude: Double?
    let latitude: Double?
}
extension KakaoGeoKeywordDTO {
    func toEntity() -> KakaoGeoKeywordEntity {
        return KakaoGeoKeywordEntity(
            meta: meta.toEntity(),
            places: documents.map { $0.toEntity() }
        )
    }
}

extension KakaoGeoKeywordMetaDTO {
    func toEntity() -> KakaoGeoKeywordMetaEntity {
        KakaoGeoKeywordMetaEntity(
            totalCount: totalCount,
            pageableCount: pageableCount,
            isEnd: isEnd
        )
    }
}

extension KakaoGeoKeywordDocumentDTO {
    func toEntity() -> KakaoGeoKeywordPlaceEntity {
        KakaoGeoKeywordPlaceEntity(
            id: id,
            name: placeName ?? "알수없음",
            address: addressName ?? "알수없음",
            roadAddress: roadAddressName ?? "알수없음",
            longitude: Double(x ?? ""),
            latitude: Double(y ?? "")
        )
    }
}
extension KakaoGeoKeywordPlaceEntity {
    func toSearchListData() -> SearchListData? {
        guard let longitude = longitude, let latitude = latitude else {
            return nil
        }
        return SearchListData(
            title: name,
            subtitle: address,
            longitude: longitude,
            latitude: latitude
        )
    }
}

