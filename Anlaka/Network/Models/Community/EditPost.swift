
import Foundation

struct EditPostRequestDTO: Codable {
    let category: String
    let title: String
    let content: String
    let latitude: Double
    let longitude: Double
    let files: [String]
}

struct EditPostResponseDTO: Decodable {
    let postId: String?
    let category: String?
    let title: String?
    let content: String?
    let geolocation: GeolocationDTO?
    let creator: UserInfoResponseDTO?
    let files: [String?]?
    let isLike: Bool?
    let likeCount: Int?
    let comments: [PostCommentResponseDTO]?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case category, title, content, geolocation, creator, files, comments, createdAt, updatedAt
        case isLike = "is_like"
        case likeCount = "like_count"
    }
}