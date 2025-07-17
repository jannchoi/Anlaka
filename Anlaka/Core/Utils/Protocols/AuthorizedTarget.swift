//
//  AuthorizedTarget.swift
//  Anlaka
//
//  Created by 최정안 on 5/24/25.
//

import Foundation
import UIKit

protocol AuthorizedTarget {
    var requiresAuthorization: Bool { get }
    var baseURL: URL { get }
    var path: String { get }
    var method: String { get }
    var header: [String: String] { get }
    var parameters: [String: Any?] { get }
    
    func asURLRequest() throws -> URLRequest
    func multipartFormData(boundary: String) -> Data
}

// MARK: - Default Implementation
extension AuthorizedTarget {
    func asURLRequest() throws -> URLRequest {
        var url = baseURL.appendingPathComponent(path)
        
        // GET 요청의 경우 쿼리 파라미터 추가
        if method == "GET" {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let queryItems = parameters.map { key, value in
                return URLQueryItem(name: key, value: "\(value)")
            }
            components?.queryItems = queryItems
            if let composedURL = components?.url {
                url = composedURL
            }
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        header.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        
        return request
    }
    
    func multipartFormData(boundary: String) -> Data {
        // 기본 구현 - 빈 데이터 반환
        return Data()
    }
}
