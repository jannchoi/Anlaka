//
//  BannerRouter.swift
//  Anlaka
//
//  Created by 최정안 on 5/18/25.
//

import Foundation

enum BannerRouter: AuthorizedTarget {
    case getBanners
    
    var requiresAuthorization: Bool {
        return true
    }

    var baseURL: URL {
        return URL(string: BaseURL.baseV1 + "/banners")!
    }

    var path: String {
        switch self {
        case .getBanners:
            return "/main"
        }
    }

    var method: String {
        switch self {
        case .getBanners:
            return "GET"
        }
    }

    var header: [String: String] {
        guard let accessToken = KeychainManager.shared.getString(forKey: .accessToken) else {return [:]}
        return [
            "SeSACKey": AppConfig.apiKey,
            "Content-Type": "application/json",
            "Authorization" : accessToken
        ]
    }

    var parameters: [String: Any?] {
        switch self {
        case .getBanners:
            return [:]
        }
    }

    func asURLRequest() throws -> URLRequest {
        var url = baseURL.appendingPathComponent(path)

        var request = URLRequest(url: url)
        request.httpMethod = method
        header.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

        return request
    }
} 