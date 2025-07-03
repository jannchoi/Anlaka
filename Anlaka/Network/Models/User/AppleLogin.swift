//
//  AppleLogin.swift
//  Anlaka
//
//  Created by 최정안 on 5/13/25.
//

import Foundation
struct AppleLoginRequestDTO: Encodable {
    let idToken: String
    let deviceToken: String
    let nick: String
}
struct AppleLoginRequestEntity {
    let idToken: String
    let deviceToken: String
    let nick: String
}
extension AppleLoginRequestEntity {
    func toDTO() -> AppleLoginRequestDTO {
        return AppleLoginRequestDTO(
            idToken: idToken,
            deviceToken: deviceToken,
            nick: nick
        )
    }
}
