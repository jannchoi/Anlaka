//
//  KakaoLogin.swift
//  Anlaka
//
//  Created by 최정안 on 5/13/25.
//

import Foundation
struct KakaoLoginRequestDTO: Encodable {
    let oauthToken: String
    let deviceToken: String
}
struct KakaoLoginRequestEntity {
    let oauthToken: String
    let deviceToken: String
}
extension KakaoLoginRequestEntity {
    func toDTO() -> KakaoLoginRequestDTO {
        return KakaoLoginRequestDTO(
            oauthToken: oauthToken,
            deviceToken: deviceToken
        )
    }
}
