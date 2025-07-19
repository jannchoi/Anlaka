import Foundation

struct PostSummaryResponseDTO: Decodable {
    let postId: String?
    let category: String?
    let title: String?
    let content: String?
    let geolocation: GeolocationDTO?
    let creator: UserInfoResponseDTO?
    let files: [String?]?
    let isLike: Bool?
    let likeCount: Int?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case category, title, content, geolocation, creator, files, isLike, likeCount, createdAt, updatedAt
    }
}

struct PostSummaryPaginationResponseDTO: Decodable {
    let data: [PostSummaryResponseDTO]?
    let next: String?
    enum CodingKeys: String, CodingKey {
        case data
        case next = "next_cursor"
    }
}

extension PostSummaryPaginationResponseDTO {
    func toEntity() -> PostSummaryPaginationResponseEntity? {
        guard let data = data,
              let next = next else {
            return nil
        }
        
        let entities = data.compactMap { $0.toEntity() }
        
        return PostSummaryPaginationResponseEntity(
            data: entities,
            next: next
        )
    }
}
struct PostSummaryPaginationResponseEntity {
    let data: [PostSummaryResponseEntity]
    let next: String
}

struct PostSummaryListResponseDTO: Decodable {
    let data: [PostSummaryResponseDTO]?
}

extension PostSummaryListResponseDTO {
    func toEntity() -> PostSummaryListResponseEntity? {
        guard let data = data else {
            return nil
        }
        
        let entities = data.compactMap { $0.toEntity() }
        
        return PostSummaryListResponseEntity(
            data: entities
        )
    }
}
struct PostSummaryListResponseEntity {
    let data: [PostSummaryResponseEntity]
}

 struct PostSummaryResponseEntity {
    let postId: String
    let category: String
    let title: String
    let content: String
    let geolocation: GeolocationEntity
    let creator: UserInfoEntity
    let files: [String]
    let isLike: Bool
    let likeCount: Int
    let createdAt: String
    let updatedAt: String
    let address: String?
 }


struct PostSummaryResponsePresentation {
    let postId: String
    let category: String
    let title: String
    let content: String
    let files: [String]
    let isLike: Bool
    let likeCount: String
    let createdAt: String
    let updatedAt: String
    let address: String?
 }


extension PostSummaryResponseDTO {
    func toEntity() -> PostSummaryResponseEntity? {
        guard let postId = postId,
              let category = category,
              let title = title,
              let content = content,
              let geolocation = geolocation,
              let geoEntity = geolocation.toEntity(),
              let creator = creator,
              let creatorEntity = creator.toEntity(),
              let files = files,
              let isLike = isLike,
              let likeCount = likeCount,
              let createdAt = createdAt,
              let updatedAt = updatedAt else {
            return nil
        }
        
        return PostSummaryResponseEntity(
            postId: postId,
            category: category,
            title: title,
            content: content,
            geolocation: geoEntity,
            creator: creatorEntity,
            files: files.compactMap { $0 },
            isLike: isLike,
            likeCount: likeCount,
            createdAt: createdAt,
            updatedAt: updatedAt,
            address: nil // 주소는 UseCase에서 처리
        )
    }
}

extension PostSummaryResponseEntity {
    func toPresentation () -> PostSummaryResponsePresentation {
        return PostSummaryResponsePresentation(
            postId: postId, 
            category: category, 
            title: title, 
            content: content, 
            files: files, 
            isLike: isLike, 
            likeCount: PresentationMapper.mapInt(likeCount), 
            createdAt: PresentationMapper.formatRelativeTime(createdAt), 
            updatedAt: PresentationMapper.formatRelativeTime(updatedAt), 
            address: address
        )
    }
}
