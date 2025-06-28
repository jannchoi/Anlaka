//
//  EstateRouter.swift
//  Anlaka
//
//  Created by 최정안 on 5/18/25.
//

import Foundation

enum EstateRouter {
    case detailEstate(estateId: String)
    case likeEstate(estateId: String, LikeEstateRequestDTO)
    case geoEstate(category: String?, lon: String?, lat: String?, maxD: String?)
    case todayEstate
    case hotEstate
    case similarEstate
    case topicEstate

    var baseURL: URL {
        return URL(string: BaseURL.baseV1 + "/estates")!
    }

    var path: String {
        switch self {
        case .detailEstate(let estateId):
            return "/\(estateId)"
        case .likeEstate(let estateId, _):
            return "/\(estateId)/like"
        case .geoEstate:
            return "/geolocation"
        case .todayEstate:
            return "/today-e"
        case .hotEstate:
            return "/hot-estates"
        case .similarEstate:
            return "/similar-estates"
        case .topicEstate:
            return "/today-topic"
        }
    }

    var method: String {
        switch self {
        case .likeEstate:
            return "POST"
        default:
            return "GET"
        }
    }

    var header: [String: String] {
        return [
            "SeSACKey": Environment.apiKey,
            "Content-Type": "application/json"
        ]
    }

    var parameters: [String: Any] {
        switch self {
        case .geoEstate(let category, let lon, let lat, let maxD):
            return [
                "category": category ?? "",
                "longitude": lon ?? "",
                "latitude": lat ?? "",
                "maxDistance": maxD ?? ""
            ]
        case .likeEstate(let estateId, _):
            return ["estate_id": estateId] // 쿼리로 요구된다면 추가
        default:
            return [:]
        }
    }

    func asURLRequest() throws -> URLRequest {
        var url = baseURL.appendingPathComponent(path)

        switch self {
        case .geoEstate, .likeEstate:
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let queryItems = parameters.map {
                URLQueryItem(name: $0.key, value: "\($0.value)")
            }
            components?.queryItems = queryItems
            if let composedURL = components?.url {
                url = composedURL
            }
        default:
            break
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        header.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

        switch self {
        case .likeEstate(_, let dto):
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(dto)
        default:
            break
        }

        return request
    }
}
