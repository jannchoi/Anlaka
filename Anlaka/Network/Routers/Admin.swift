import Foundation

enum AdminRouter: AuthorizedTarget {
    case uploadAdminRequest(AdminRequestMockData)

    var baseURL: URL {
        return URL(string: BaseURL.baseV1)!
    }

    var requiresAuthorization: Bool {
        return true
    }
    
    var path: String {
        switch self {
        case .uploadAdminRequest:
            return "/estates"
        }
    }
    
    var method: String {
        switch self {
        case .uploadAdminRequest:
            return "POST"
        }
    }
    
    var header: [String: String] {
        var headers = [
            "SeSACKey": AppConfig.apiKey,
            "Content-Type": "application/json"
        ]
        
        if let accessToken = UserDefaultsManager.shared.getString(forKey: .accessToken) {
            headers["Authorization"] = accessToken
        }
        
        return headers
    }
    var parameters: [String : Any?] {
        return [:]
    }
    
    func asURLRequest() throws -> URLRequest {
        var url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        header.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        
        switch self {
        case .uploadAdminRequest(let dto):
            request.httpBody = try JSONEncoder().encode(dto)
        }
        
        return request
    }
}
