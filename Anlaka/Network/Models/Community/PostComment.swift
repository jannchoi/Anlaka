
import Foundation


struct PostCommentRequestDTO: Codable {
    let parent_comment_id: String?
    let comment: String
}

struct PostCommentResponseDTO: Decodable {
    let commentId: String?
    let content: String?
    let creator: UserInfoResponseDTO?
    let replies: [CommentResponseDTO]?

    enum CodingKeys: String, CodingKey {
        case commentId = "comment_id"
        case content, creator, replies
    }
}
