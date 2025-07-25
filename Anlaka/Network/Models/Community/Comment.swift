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

extension CommentResponseDTO {
    func toEntity() -> CommentResponseEntity? {
        guard let commentId = commentId,
              let content = content,
              let createdAt = createdAt,
              let creator = creator?.toEntity() else {
            return nil
        }
        
        return CommentResponseEntity(
            commentId: commentId,
            content: content,
            createdAt: createdAt,
            creator: creator
        )
    }
}


