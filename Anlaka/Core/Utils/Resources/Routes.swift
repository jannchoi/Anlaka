//
//  Routes.swift
//  Anlaka
//
//  Created by 최정안 on 5/15/25.
//

import Foundation

enum LoginRoute: Hashable {
    case home
    case signUp
}

enum HomeRoute: Hashable {
    case detail(estateId: String)
    case category(categoryType: CategoryType)
    case estatesAll(type: EstateListType)
    case topicWeb(url: URL)
    case search
}
enum EstateListType: Hashable {
    case latest
    case hot
}
enum CategoryType: String, Hashable,CaseIterable {
    case Apartment = "아파트"
    case Officetel = "오피스텔"
    case OneRoom = "원룸"
    case Storefront = "주상복합"
    case Villa = "빌라"
}
