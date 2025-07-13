//
//  EstateRouter.swift
//  Anlaka
//
//  Created by 최정안 on 5/18/25.
//

import Foundation

enum EstateRouter: AuthorizedTarget {
    case detailEstate(estateId: String)
    case likeEstate(estateId: String, LikeEstateRequestDTO)
    case geoEstate(category: String?, lon: String?, lat: String?, maxD: String?)
    case todayEstate
    case hotEstate
    case similarEstate
    case topicEstate
    case likeLists(category: String?, next: String?)
    
    var requiresAuthorization: Bool {
        return true
    }

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
            return "/today-estates"
        case .hotEstate:
            return "/hot-estates"
        case .similarEstate:
            return "/similar-estates"
        case .topicEstate:
            return "/today-topic"
        case .likeLists:
            return "/likes/me"
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
        guard let accessToken = UserDefaultsManager.shared.getString(forKey: .accessToken) else {return [:]}
        //print("accessToken: \(accessToken)")
        return [
            "SeSACKey": AppConfig.apiKey,
            "Content-Type": "application/json",
            "Authorization" : accessToken
        ]
    }

    var parameters: [String: Any?] {
        switch self {
        case .geoEstate(let category, let lon, let lat, let maxD):
            var params: [String: Any] = [
                "longitude": lon ?? "",
                "latitude": lat ?? "",
                "maxDistance": maxD ?? ""
            ]
            
            // category가 nil이 아니고 비어있지 않은 경우에만 추가
            if let category = category, !category.isEmpty {
                params["category"] = category
            }
            //print(params)
            return params
            
        case .likeEstate(let estateId, _):
            return ["estate_id": estateId] // 쿼리로 요구된다면 추가
        case .likeLists(let category, let next):
            var params: [String: Any] = ["limit": "5"]
            // category가 nil이 아니고 비어있지 않은 경우에만 추가
            if let category = category, !category.isEmpty {
                params["category"] = category
            }
            if let next = next, !next.isEmpty {
                params["next"] = next
            }
            return params
        default:
            return [:]
        }
    }

    func asURLRequest() throws -> URLRequest {
        var url = baseURL.appendingPathComponent(path)

        switch self {
        case .geoEstate, .likeEstate, .likeLists:
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
