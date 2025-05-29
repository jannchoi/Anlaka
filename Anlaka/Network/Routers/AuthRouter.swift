//
//  AuthRouter.swift
//  Anlaka
//
//  Created by 최정안 on 5/12/25.
//

import Foundation
enum AuthRouter {
    case getRefreshToken(refToken: String)
    case log
    
    var baseURL: URL { URL(string: BaseURL.baseV1)!}

    var path: String {
        switch self {
        case .getRefreshToken:
            return "/auth/refresh"
        case .log:
            return "/log"
        }
    }

    var method: String {
        return "GET"
    }

    var header: [String: String] {
        switch self {
        case .getRefreshToken(let refToken):
            return [
                "SeSACKey": Environment.apiKey,
                "RefreshToken": refToken
            ]
        case .log:
            return ["SeSACKey": Environment.apiKey]
        }
    }

    func asURLRequest() throws -> URLRequest {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        header.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        return request
    }
}
