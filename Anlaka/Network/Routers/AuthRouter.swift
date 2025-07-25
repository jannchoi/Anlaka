//
//  AuthRouter.swift
//  Anlaka
//
//  Created by 최정안 on 5/12/25.
//

import Foundation
enum AuthRouter: AuthorizedTarget {
    
    
    case getRefreshToken
    case log
    
    var baseURL: URL { URL(string: BaseURL.baseV1)!}
    
    var requiresAuthorization: Bool {
        switch self {
        case .getRefreshToken:
            return false
        case .log:
            return false
        }
    }
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
        case .getRefreshToken:
            guard let accessToken = UserDefaultsManager.shared.getString(forKey: .accessToken), let refreshToken = UserDefaultsManager.shared.getString(forKey: .refreshToken) else {return [:]}
            return [
                "SeSACKey": AppConfig.apiKey,
                "RefreshToken": refreshToken,
                "Authorization" : accessToken,
                "Content-Type": "application/json"
            ]
        case .log:
            return ["SeSACKey": AppConfig.apiKey]
        }
    }
    var parameters: [String : Any?] {
        return [:]
    }
    func asURLRequest() throws -> URLRequest {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        header.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        return request
    }
}
