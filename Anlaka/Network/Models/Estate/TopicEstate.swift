//
//  TopicEstate.swift
//  Anlaka
//
//  Created by 최정안 on 5/18/25.
//

import Foundation
struct TopicEstateDTO: Decodable {
    let data: [TopicEstateItemDTO]
}

struct TopicEstateItemDTO: Decodable {
    let title: String?
    let content: String?
    let date: String?
    let link: String? // optional
}
struct TopicEstateEntity {
    let items: [TopicEstateItemEntity]
}

struct TopicEstateItemEntity {
    let title: String
    let content: String
    let date: String
    let link: String?
}

extension TopicEstateDTO {
    func toEntity() -> TopicEstateEntity {
        let itemEntities = data.compactMap{ $0.toEntity() }
        return TopicEstateEntity(items: itemEntities)
    }
}

extension TopicEstateItemDTO {
    func toEntity() -> TopicEstateItemEntity? {
        guard let title = title else {return nil}
        return TopicEstateItemEntity(
            title: title,
            content: content ?? "알 수 없음",
            date: date ?? "알 수 없음",
            link: link
        )
    }
}
