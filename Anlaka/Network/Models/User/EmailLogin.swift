//
//  EmailLogin.swift
//  Anlaka
//
//  Created by 최정안 on 5/12/25.
//

import Foundation
struct EmailLoginRequestDTO: Encodable {
    let email: String
    let password: String
    let deviceToken: String?
}

struct EmailLoginRequestEntity {
    let email: String
    let password: String
    let deviceToken: String?
}

extension EmailLoginRequestEntity {
    func toDTO() -> EmailLoginRequestDTO {
        return EmailLoginRequestDTO(
            email: email,
            password: password,
            deviceToken: deviceToken
        )
    }
}
