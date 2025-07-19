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
struct PostSummaryPaginationResponseEntity {
    let data: [PostSummaryResponseEntity]
    let next: String
}

struct PostSummaryListResponseDTO: Decodable {
    let data: [PostSummaryResponseDTO]?
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
 }
struct PostSummaryResponseWithAddress {
    let summary: PostSummaryResponsePresentation
    let address: String
}

extension PostSummaryResponseEntity {
    func toPresentation () -> PostSummaryResponsePresentation {
        return PostSummaryResponsePresentation(postId: postId, category: category, title: title, content: content, files: files, isLike: isLike, likeCount: "\(likeCount)", createdAt: PresentationMapper.formatRelativeTime(createdAt), updatedAt: PresentationMapper.formatRelativeTime(updatedAt))
    }
}
