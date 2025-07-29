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
    case detail
    case category
    case latestAll
    case hotAll
}
