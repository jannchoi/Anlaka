
import Foundation


struct PostCommentRequestDTO: Codable {
    let parent_comment_id: String?
    let content: String
}

struct PostCommentResponseDTO: Decodable {
    let commentId: String?
    let content: String?
    let createdAt: String?
    let creator: UserInfoResponseDTO?
    let replies: [CommentResponseDTO?]?

    enum CodingKeys: String, CodingKey {
        case commentId = "comment_id"
        case content, createdAt, creator, replies
    }
}
struct PostCommentResponseEntity: Equatable, Hashable {
    let commentId: String
    var content: String
    let createdAt: String
    let creator: UserInfoEntity
    var replies: [CommentResponseEntity]
    // Optimistic update 및 실패 상태 관리용
    var sendFailed: Bool = false
    var isTemp: Bool = false
    var tempId: String? = nil
}
extension PostCommentResponseDTO {
    func toEntity() -> PostCommentResponseEntity? {
        guard let commentId = commentId, 
              let content = content, 
              let createdAt = createdAt,
              let creator = creator, 
              let creatorEntity = creator.toEntity() else {
            return nil
        }
        let validReplies = replies?.compactMap { $0?.toEntity() } ?? []
        
        return PostCommentResponseEntity(
            commentId: commentId, 
            content: content, 
            createdAt: createdAt,
            creator: creatorEntity, 
            replies: validReplies
        )
    }
}

extension PostCommentResponseEntity {
    func toReplyEntity() -> CommentResponseEntity {
        CommentResponseEntity(
            commentId: self.commentId,
            content: self.content,
            createdAt: self.createdAt,
            creator: self.creator,
            geolocation: nil, // 필요시 매핑
            replies: self.replies,
            sendFailed: self.sendFailed,
            isTemp: self.isTemp,
            tempId: self.tempId
        )
    }
}

extension CommentResponseEntity {
    func toPostCommentEntity() -> PostCommentResponseEntity {
        PostCommentResponseEntity(
            commentId: self.commentId,
            content: self.content,
            createdAt: self.createdAt,
            creator: self.creator,
            replies: self.replies ?? [],
            sendFailed: self.sendFailed,
            isTemp: self.isTemp,
            tempId: self.tempId
        )
    }
}
