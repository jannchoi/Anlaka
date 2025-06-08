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
    case category(categoryType: String)
    case estatesAll(type: EstateListType)
    case topicWeb(url: URL)
    case search
}
enum EstateListType: Hashable {
    case latest
    case hot
}
