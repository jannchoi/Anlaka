//
//  EmailValidation.swift
//  Anlaka
//
//  Created by 최정안 on 5/12/25.
//

import Foundation
// Request DTO
struct EmailValidationRequestDTO: Encodable {
    let email: String
}

// Response DTO
struct EmailValidationResponseDTO: Decodable {
    let message: String
}

// Entity
struct EmailValidationResponseEntity {
    let message: String
}

// Mapper
extension EmailValidationResponseDTO {
    func toEntity() -> EmailValidationResponseEntity {
        return EmailValidationResponseEntity(message: message)
    }
}

// Entity
struct EmailValidationRequestEntity {
    let email: String
}

// Mapper
extension EmailValidationRequestEntity {
    func toDTO() -> EmailValidationRequestDTO {
        return EmailValidationRequestDTO(email: email)
    }
}
