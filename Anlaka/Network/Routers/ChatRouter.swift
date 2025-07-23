import Foundation
import UIKit

enum ChatRouter: AuthorizedTarget {
    
    case getChatRoom(ChatRoomRequestDTO)
    case getChatRooms
    case sendMessage(roomId: String, ChatRequestDTO)
    case getChatList(roomId: String, from: String?)
    case uploadFiles(roomId: String, [FileData])
    
    var baseURL: URL { URL(string: BaseURL.baseV1)!}
    
    var requiresAuthorization: Bool {
        return true
    }
    
    var path: String {
        switch self {
        case .getChatRooms, .getChatRoom:
            return "/chats"
        case .sendMessage(let roomId, _):
            return "/chats/\(roomId)"
        case .getChatList(let roomId, _):
            return "/chats/\(roomId)"
        case .uploadFiles(let roomId, _):
            return "/chats/\(roomId)/files"
        }
    }
    
    var method: String {
        switch self {
        case .getChatRoom, .sendMessage, .uploadFiles:
            return "POST"
        case .getChatRooms, .getChatList:
            return "GET"
        }
    }
    
    var header: [String: String] {
        guard let accessToken = UserDefaultsManager.shared.getString(forKey: .accessToken) else {return [:]}
        return [
            "SeSACKey": AppConfig.apiKey,
            "Content-Type": "application/json",
            "Authorization" : accessToken
        ]
    }
    
    var parameters: [String: Any?] {
        switch self {
        case .sendMessage(let roomId, _):
            return ["room_id": roomId]
        case .uploadFiles(let roomId, _):
            return ["room_id": roomId]
        case .getChatList(let roomId, let from):
            var params = ["room_id": roomId]
            if let from = from {
                params["from"] = from
            }
            return params
        case .getChatRooms:
            return [:]
        default:
            return [:]
        }
    }
}

// MARK: - ChatRouter Specific Implementation
extension ChatRouter {
    func multipartFormData(boundary: String) -> Data {
        var body = Data()
        
        switch self {
        case .uploadFiles(let roomId, let dto):
            // 채팅 파일 업로드 특화 로직
            // 1. 확장자 제한: jpg, png, jpeg, gif, pdf
            // 2. 용량 제한: 5MB
            // 3. 파일 개수: 5개
            // 4. request body: multipart/form-data - "files" : [String]
            
            let validExtensions = ["jpg", "jpeg", "png", "gif", "pdf"]
            let maxSize: Int = 5 * 1024 * 1024 // 5MB
            let maxFileCount = 5
            
            // 파일 개수 제한 확인
            let filesToUpload = Array(dto.prefix(maxFileCount))
            
            // 각 파일에 대해 multipart/form-data 구성
            for (index, file) in filesToUpload.enumerated() {
                // 파일 확장자 검증
                guard file.isValidExtension else {
                    print("Invalid file extension: \(file.fileExtension)")
                    continue
                }
                
                // 파일 크기 검증
                guard file.data.count <= maxSize else {
                    print("File too large: \(file.fileName)")
                    continue
                }
                
                // 파일 데이터 추가
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"files\"; filename=\"\(file.fileName)\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: \(file.mimeType)\r\n\r\n".data(using: .utf8)!)
                body.append(file.data)
                body.append("\r\n".data(using: .utf8)!)
            }
            
            // room_id 파라미터 추가
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"room_id\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(roomId)\r\n".data(using: .utf8)!)
            
        default:
            break
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }
    
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
        
        var headers = header
        let boundary = "Boundary-\(UUID().uuidString)"
        
        // uploadFiles 케이스일 때 Content-Type 변경
        if case .uploadFiles = self {
            headers["Content-Type"] = "multipart/form-data; boundary=\(boundary)"
        }
        
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        
        // POST, PUT 요청의 경우 body 추가
        if method == "POST" || method == "PUT" {
            if case .uploadFiles = self {
                request.httpBody = multipartFormData(boundary: boundary)
            } else {
                // DTO를 직접 인코딩
                let encoder = JSONEncoder()
                switch self {
                case .getChatRoom(let dto):
                    request.httpBody = try encoder.encode(dto)
                case .sendMessage(_, let dto):
                    request.httpBody = try encoder.encode(dto)
                default:
                    break
                }
            }
        }
        
        return request
    }
}


