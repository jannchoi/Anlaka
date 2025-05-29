//
//  ProfileInfo.swift
//  Anlaka
//
//  Created by 최정안 on 5/25/25.
//

import Foundation
struct ProfileInfo: Codable {
    let userid: String
    let email: String
    let nick: String
    let profileImage: String?
    let phoneNum: String?
    let introduction: String?
}
