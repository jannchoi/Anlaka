//
//  Log.swift
//  Anlaka
//
//  Created by 최정안 on 5/20/25.
//

import Foundation

struct LogListResponseDTO: Decodable {
    let count: Int?
    let logs: [LogDTO]?
}

struct LogDTO: Decodable {
    let date: String?             // ISO8601 형식 ("2025-05-08T11:43:17.000Z")
    let name: String?
    let method: String?
    let routePath: String?
    let body: String?
    let contentType: String?
    let statusCode: String?
    
    // CodingKeys로 snake_case → camelCase 매핑
    enum CodingKeys: String, CodingKey {
        case date
        case name
        case method
        case routePath = "route_path"
        case body
        case contentType
        case statusCode = "status_code"
    }
}

