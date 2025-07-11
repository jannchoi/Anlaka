//
//  Routes.swift
//  Anlaka
//
//  Created by 최정안 on 5/15/25.
//

import Foundation

enum LoginRoute: Hashable {
    case signUp
}

enum HomeRoute: Hashable {
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
enum SearchMapRoute: Hashable {
    case detail(estateId: String)
}

// MARK: - Route Definition
enum MyPageRoute: Hashable {
    case chatRoom(roomId: String, di: DIContainer)
    case editProfile
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        switch self {
        case .chatRoom(let roomId, _):
            hasher.combine("chatRoom")
            hasher.combine(roomId)
        case .editProfile:
            hasher.combine("editProfile")
        }
    }
    
    static func == (lhs: MyPageRoute, rhs: MyPageRoute) -> Bool {
        switch (lhs, rhs) {
        case (.chatRoom(let lRoomId, _), .chatRoom(let rRoomId, _)):
            return lRoomId == rRoomId
        case (.editProfile, .editProfile):
            return true
        default:
            return false
        }
    }
}
enum PaymentRoute: Hashable {
    case payment(PaymentContainer)
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        switch self {
        case .payment:
            hasher.combine("payment")
        }
    }
    
    static func == (lhs: PaymentRoute, rhs: PaymentRoute) -> Bool {
        switch (lhs, rhs) {
        case (.payment, .payment):
            return true
        }
    }
}
