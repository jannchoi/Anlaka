

import Foundation

enum OrderRouter: AuthorizedTarget {

    case createOrder(orderRequestDTO: CreateOrderRequestDTO)
    case getOrders
    var requiresAuthorization: Bool {
        return true
    }
    var baseURL: URL {
        return URL(string: BaseURL.baseV1 + "/orders")!
    }
    var path: String {
        return ""
    }
    var method: String {
        switch self {
        case .createOrder:
            return "POST"
        case .getOrders:
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
        return [:]
    }
    func asURLRequest() throws -> URLRequest {
        var url = baseURL.appendingPathComponent(path)
        switch self {
        case .getOrders:
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
        case .createOrder(let dto):
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(dto)
        default:
            break
        }
        return request
    }
}
