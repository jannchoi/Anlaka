//
//  CustomError.swift
//  Anlaka
//
//  Created by 최정안 on 6/6/25.
//

import Foundation
enum CustomError: Error {
    case nilResponse
    
    var errorDescription: String {
        switch self {
        case .nilResponse:
            return "해당 값이 존재하지 않습니다."
        }
    }
}
