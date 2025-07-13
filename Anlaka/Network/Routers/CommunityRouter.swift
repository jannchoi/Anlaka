import Foundation
import UIKit

enum CommunityRouter: AuthorizedTarget {
    case postFile(files: [FileData])
    case posting(dto: PostRequestDTO)
    case getLocationPost(category: String?, longitude: String?, latitude: String?, maxDistance: String?, next: String?, order: String?)
    case searchPostTitle(title: String?)
    case getPost(post_id: String)
    case editPost(post_id: String, dto: EditPostRequestDTO)
    case deletePost(post_id: String)
    case likePost(post_id: String, dto: LikeEstateRequestDTO)
    case searchUserPost(user_id: String)
    case searchMyLikePost
    case postComment(post_id: String, dto: PostCommentRequestDTO)
    case editComment(post_id: String, comment_id: String, dto: EditCommentRequestDTO)
    case deleteComment(post_id: String, comment_id: String)

    var baseURL: URL { URL(string: BaseURL.baseV1)!}
    
    var requiresAuthorization: Bool {
        return true
    }
    
    var path: String {
        switch self {
        case .postFile:
            return "/posts/files"
        case .posting:
            return "/posts"
        case .getLocationPost:
            return "/posts/geolocation"
        case .searchPostTitle:
            return "/posts/search"
        case .getPost(let post_id):
            return "/posts/\(post_id)"
        case .editPost(let post_id, _):
            return "/posts/\(post_id)"
        case .deletePost(let post_id):
            return"/posts/\(post_id)"
        case .likePost(let post_id, _):
            return "/posts/\(post_id)/like"
        case .searchUserPost(let user_id):
            return "/posts/users/\(user_id)"
        case .searchMyLikePost:
            return "/posts/likes/me"
        case .postComment(let post_id, _):
            return "/posts/\(post_id)/comments"
        case .editComment(let post_id, let comment_id, _):
            return "/posts/\(post_id)/comments/\(comment_id)"
        case .deleteComment(let post_id, let comment_id):
            return "/posts/\(post_id)/comments/\(comment_id)"
        }
    }
    
    var method: String {
        switch self {
        case .postFile, .posting, .likePost, .postComment:
            return "POST"
        case .getLocationPost, .searchPostTitle, .getPost, .searchUserPost, .searchMyLikePost:
            return "GET"
        case .deletePost, .deleteComment:
            return "DELETE"
        case .editPost, .editComment:
            return "PUT"
        }
    }
    
    var header: [String: String] {
        guard let accessToken = UserDefaultsManager.shared.getString(forKey: .accessToken) else {return [:]}
        return [
            "SeSACKey": AppConfig.apiKey,
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization" : accessToken
        ]
    }
    
    var parameters: [String: Any?] {
        switch self {
        case .getLocationPost(let category, let longitude, let latitude, let maxDistance, let next, let order):
            return ["category": category, "longitude": longitude, "latitude": latitude, "maxDistance": maxDistance, "limit": 10, "next": next, "order": order]
        case .searchPostTitle(let title):
            return ["title": title]
        case .getPost(let post_id), .editPost(let post_id, _), .deletePost(let post_id), .likePost(let post_id, _):
            return ["post_id": post_id]
        case .postComment(let post_id, _):
            return ["post_id": post_id]
        case .editComment(let post_id, let comment_id, _), .deleteComment(let post_id, let comment_id):
            return ["post_id": post_id, "comment_id": comment_id]
        default:
            return [:]
        }
    }
}

// MARK: - CommunityRouter Specific Implementation
extension CommunityRouter {
    func multipartFormData(boundary: String) -> Data {
        var body = Data()
        
        switch self {
        case .postFile(let files):
            // 커뮤니티 파일 업로드 특화 로직
            // 1. 확장자 제한: jpg, png, jpeg, gif, webp, mp4, mov, avi, mkv, wmv
            // 2. 용량 제한: 5MB
            // 3. 파일 개수: 5개
            // 4. request body: multipart/form-data - "files" : [String]
            
            let validExtensions = ["jpg", "jpeg", "png", "gif", "webp", "mp4", "mov", "avi", "mkv", "wmv"]
            let maxSize: Int = 5 * 1024 * 1024 // 5MB
            let maxFileCount = 5
            
            // 파일 개수 제한 확인
            let filesToUpload = Array(files.prefix(maxFileCount))
            
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
            
        default:
            break
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }
    
    func asURLRequest() throws -> URLRequest {
        var url = baseURL.appendingPathComponent(path)
        
        // GET 요청 또는 특정 POST 케이스의 경우 쿼리 파라미터 추가
        let shouldAddQueryParams: Bool
        switch self {
        case .postComment, .likePost:
            shouldAddQueryParams = method == "POST"
        default:
            shouldAddQueryParams = method == "GET"
        }
        
        if shouldAddQueryParams {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let queryItems = parameters.compactMap { (key: String, value: Any?) -> URLQueryItem? in
                // Optional 값을 안전하게 처리
                guard let unwrappedValue = value else { return nil }
                return URLQueryItem(name: key, value: "\(unwrappedValue)")
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
        
        // postFile 케이스일 때 Content-Type 변경
        if case .postFile = self {
            headers["Content-Type"] = "multipart/form-data; boundary=\(boundary)"
        }
        
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        
        // POST, PUT 요청의 경우 body 추가
        if method == "POST" || method == "PUT" {
            if case .postFile = self {
                request.httpBody = multipartFormData(boundary: boundary)
            } else {
                // DTO를 직접 인코딩
                let encoder = JSONEncoder()
                switch self {
                case .posting(let dto):
                    request.httpBody = try encoder.encode(dto)
                case .likePost(_, let dto):
                    request.httpBody = try encoder.encode(dto)
                case .postComment(_, let dto):
                    request.httpBody = try encoder.encode(dto)
                case .editComment(_, _, let dto):
                    request.httpBody = try encoder.encode(dto)
                case .editPost(_, let dto):
                    request.httpBody = try encoder.encode(dto)
                default:
                    break
                }
            }
        }
        
        return request
    }
}
