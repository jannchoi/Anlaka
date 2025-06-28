//
//  SimilarEstate.swift
//  Anlaka
//
//  Created by 최정안 on 5/18/25.
//

import Foundation
struct SimilarEstateResponseDTO: Decodable {
    let data: [EstateSummaryDTO]
}

struct SimilarEstateEntity {
    let data: [SimilarSummaryEntity]
}

extension SimilarEstateResponseDTO {
    func toEntity() -> SimilarEstateEntity {
        return .init(data: data.compactMap { $0.toSimilarEntity() })
    }
}
struct SimilarEstatePresentation {
    let data: [SimilarSummaryPresentation]
}
struct SimilarSummaryEntity {
    let estateId: String
    let category: String
    let thumbnail: String
    let deposit: Double?
    let monthlyRent: Double?
    let area: Double?
    let geolocation: GeolocationEntity
    let isRecommended: Bool
}
struct SimilarSummaryPresentation {
    let estateId: String
    let category: String
    let thumbnail: String
    let deposit: String
    let monthlyRent: String
    let area: String
    let isRecommended: Bool
}
struct SimilarEstateWithAddress {
    let summary: SimilarSummaryPresentation
    let address: String // roadRegion3
}

extension SimilarEstateEntity {
    func toPresentation () -> SimilarEstatePresentation {
        return .init(data: data.map{$0.toPresentation()})
    }
}
extension SimilarSummaryEntity {
    func toPresentation () -> SimilarSummaryPresentation {
        return SimilarSummaryPresentation(estateId: estateId, category: category, thumbnail: thumbnail, deposit: PresentationMapper.formatToShortUnitString(deposit), monthlyRent: PresentationMapper.formatToShortUnitString(monthlyRent), area: PresentationMapper.formatArea(area), isRecommended: isRecommended)
    }
}
