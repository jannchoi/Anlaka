import Foundation

protocol CommunityNetworkRepository {
    func postFile(files: [FileData]) async throws -> [FileEntity]
    func postPosting(posting: PostRequestDTO) async throws -> PostResponseEntity
    func getLocationPost(category: String?, latitude: Double?, longitude: Double?, maxDistance: Double?, next: String?, order: String?) async throws -> PostSummaryPaginationResponseEntity
    func searchPostByTitle(title: String) async throws -> PostSummaryListResponseEntity
    func getPostById(postId: String) async throws -> PostResponseEntity
    func editPost(postId: String, posting: EditPostRequestDTO) async throws -> PostResponseEntity
    func deletePost(postId: String) async throws -> Bool
    func likePost(postId: String, status: Bool) async throws -> LikeEstateEntity
    func searchPostByUserId(userId: String) async throws -> PostSummaryPaginationResponseEntity
    func searchPostByMyLike() async throws -> PostSummaryPaginationResponseEntity
    func postComment(postId: String, comment: PostCommentRequestDTO) async throws -> CommentResponseEntity
    func editComment(postId: String, commentId: String, comment: EditCommentRequestDTO) async throws -> CommentResponseEntity
    func deleteComment(postId: String, commentId: String) async throws -> Bool
} 
