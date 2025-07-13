//
//  AppleLogin.swift
//  Anlaka
//
//  Created by 최정안 on 5/13/25.
//

import Foundation
struct AppleLoginRequestDTO: Encodable {
    let idToken: String
    let deviceToken: String?
    let nick: String?
}
struct AppleLoginRequestEntity {
    let idToken: String?
    let deviceToken: String?
    let nick: String?
}
extension AppleLoginRequestEntity {
    func toDTO() -> AppleLoginRequestDTO? {
        guard let idToken = idToken else {return nil}
        return AppleLoginRequestDTO(
            idToken: idToken,
            deviceToken: deviceToken,
            nick: nick
        )
    }
}
