import Foundation



struct CommentResponseDTO: Decodable {
    let commentId: String?
    let content: String?
    let createdAt: String?
    let creator: UserInfoResponseDTO?
    
    enum CodingKeys: String, CodingKey {
        case commentId = "comment_id"
        case content, createdAt, creator
    }

}
struct CommentResponseEntity {
    let commentId: String
    let content: String
    let createdAt: String
    let creator: UserInfoEntity
}
