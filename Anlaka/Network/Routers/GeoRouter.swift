//
//  GeoRouter.swift
//  Anlaka
//
//  Created by 최정안 on 5/18/25.
//

import Foundation

enum GeoRouter {
    case getAddress(lon: Double, lat: Double)
    case getGeolocation(query: String)
    
    var baseURL: URL {URL(string: BaseURL.geoBaseURL)!}
    
    var path: String {
        switch self {
        case .getAddress:
            return "/geo/coord2address.json"
        case .getGeolocation(let query):
            return "/search/address.json"
        }
    }
    
    var method: String {
        return "GET"
    }
    var header: [String: String] {
        let restKey = "KakaoAK" + " " + Environment.kakaoRestKey
        return ["Authorization": restKey]
    }
    var parameters: [String: Any] {
        switch self {
        case .getAddress(let lon, let lat):
            return ["x": lon, "y": lat]
        case .getGeolocation(let query):
            return ["query": query]
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        var url = baseURL.appendingPathComponent(path)
        switch self {
        case .getAddress, .getGeolocation:
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let queryItems = parameters.map{URLQueryItem(name: $0.key, value: "\($0.value)")}
            components?.queryItems = queryItems
            if let composedURL = components?.url {
                url = composedURL
            }
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        header.forEach{ request.setValue($0.value, forHTTPHeaderField: $0.key)}
        return request
    }
}
