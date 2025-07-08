
import Foundation


struct PostRequestDTO: Codable {
    let category: String
    let title: String
    let content: String
    let longitude: Double
    let latitude: Double
    let files: [String]

    enum CodingKeys: String, CodingKey {
        case category, title, content, longitude, latitude, files
    }
}

struct PostResponseDTO: Decodable {
    let postId: String?
    let category: String?
    let title: String?
    let content: String?
    let geolocation: GeolocationDTO?
    let creator: UserInfoResponseDTO?
    let files: [String?]?
    let isLike: Bool?
    let likeCount: Int?
    let comments: [CommentResponseDTO]?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case category, title, content, geolocation, creator, files, comments, createdAt, updatedAt
        case isLike = "is_like"
        case likeCount = "like_count"
    }
}

struct PostResponseEntity {
    let postId: String
    let category: String
    let title: String
    let content: String
    let geolocation: GeolocationEntity
    let creator: UserInfoEntity
    let files: [FileEntity]
    let comments: [CommentResponseEntity]
    let createdAt: String
    let updatedAt: String

}