

import Foundation

enum PaymentRouter: AuthorizedTarget {
    
    case validatePayment(paymentRequestDTO: ReceiptPaymentRequestDTO)
    case getPayment(orderCode: String)
    
     var baseURL: URL {
        return URL(string: BaseURL.baseV1 + "/payments")!
    }
    var requiresAuthorization: Bool {
        return true
    }
    var path: String {
        switch self {
        case .validatePayment:
            return "/validation"
        case .getPayment(let orderCode):
            return "/\(orderCode)"
        }
    }
    var method: String {
        switch self {
        case .validatePayment:
            return "POST"
        case .getPayment:
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
        case .validatePayment:
            return [:]
        case .getPayment(let orderCode):
            return ["order_code": orderCode]
        }
    }
    func asURLRequest() throws -> URLRequest {
        var url = baseURL.appendingPathComponent(path)
        switch self {
        case .getPayment:
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
        case .validatePayment(let dto):
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(dto)
        default:
            break
        }
        return request
    }
}
