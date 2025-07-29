import Foundation

enum ChatRouter: AuthorizedTarget {
    
    case getChatRoom(ChatRoomRequestDTO)
    case getChatRooms
    case sendMessage(roomId: String, ChatRequestDTO)
    case getChatList(roomId: String, from: String?)
    case uploadFiles(roomId: String, ChatFilesRequestDTO)
    
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
    
    var parameters: [String: Any] {
        switch self {
        case .sendMessage(let roomId, _), .uploadFiles(let roomId, _):
            return ["room_id": roomId]
        case .getChatList(let roomId, let from):
            if let from = from {
                return ["room_id": roomId, "from": from]
            } else {
                return ["room_id": roomId]
            }
        case .getChatRoom, .getChatRooms:
            return [:]
        }
    }
    
    // multipartFormData 함수 수정
    private func multipartFormData(boundary: String) -> Data {
        var body = Data()
        
        switch self {
        case .uploadFiles(let roomId, let dto):
            // 파일 데이터 추가
            for (index, file) in dto.files.enumerated() {
                // 파일 확장자 검증
                guard file.isValidExtension else {
                    print("Invalid file extension: \(file.fileExtension)")
                    continue
                }
                
                // 파일 데이터 추가
                body.append("--\(boundary)\r\n")
                body.append("Content-Disposition: form-data; name=\"files\"; filename=\"\(file.fileName)\"\r\n")
                body.append("Content-Type: \(file.mimeType)\r\n\r\n")
                body.append(file.data)
                body.append("\r\n")
            }
            
            // room_id 파라미터 추가
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"room_id\"\r\n\r\n")
            body.append("\(roomId)\r\n")
            
            // 마지막 boundary 추가
            body.append("--\(boundary)--\r\n")
            
            return body
        default:
            return Data()
        }
    }
    
    // MIME 타입을 결정하는 헬퍼 함수
    private func getMimeType(for filePath: String) -> String {
        let fileExtension = URL(fileURLWithPath: filePath).pathExtension.lowercased()
        
        switch fileExtension {
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "gif":
            return "image/gif"
        case "pdf":
            return "application/pdf"
        case "txt":
            return "text/plain"
        case "mp4":
            return "video/mp4"
        case "mov":
            return "video/quicktime"
        default:
            return "application/octet-stream"
        }
    }
    
    // asURLRequest 함수의 uploadFiles 케이스 수정
    func asURLRequest() throws -> URLRequest {
        let url = baseURL.appendingPathComponent(path)
        var finalURL = url
        
        switch self {
        case .getChatList, .sendMessage:
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let queryItems = parameters.map {
                URLQueryItem(name: $0.key, value: "\($0.value)")
            }
            components?.queryItems = queryItems
            if let composedURL = components?.url {
                finalURL = composedURL
            }
        case .getChatRooms, .getChatRoom, .uploadFiles:
            break
        }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = method
        
        // uploadFiles 케이스일 때는 Content-Type을 multipart/form-data로 설정
        var headers = header
        let boundary = "Boundary-\(UUID().uuidString)"
        
        if case .uploadFiles = self {
            headers["Content-Type"] = "multipart/form-data; boundary=\(boundary)"
        }
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        
        switch self {
        case .getChatRoom(let dto):
            request.httpBody = try JSONEncoder().encode(dto)
        case .sendMessage(_, let dto):
            request.httpBody = try JSONEncoder().encode(dto)
        case .uploadFiles:
            request.httpBody = multipartFormData(boundary: boundary)
        default:
            break
        }
        return request
    }
}


