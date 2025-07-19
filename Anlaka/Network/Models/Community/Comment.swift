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
struct CommentResponseEntity: Equatable, Hashable {
    let commentId: String
    var content: String
    let createdAt: String
    let creator: UserInfoEntity
    let geolocation: GeolocationEntity?
    var replies: [CommentResponseEntity]?
    // Optimistic update 및 실패 상태 관리용
    var sendFailed: Bool = false
    var isTemp: Bool = false
    var tempId: String? = nil
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
            creator: creator,
            geolocation: nil, // TODO: geolocation 정보 추가
            replies: nil // TODO: replies 정보 추가
        )
    }
}


