import Foundation

struct PostingUseCase {
    private let communityRepository: CommunityNetworkRepository
    private let addressRepository: AddressNetworkRepository
    
    init(communityRepository: CommunityNetworkRepository, addressRepository: AddressNetworkRepository) {
        self.communityRepository = communityRepository
        self.addressRepository = addressRepository
    }
    

    func uploadFiles(files: [FileData]) async throws -> [FileEntity] {
        return try await communityRepository.postFile(files: files)
    }

    // 게시글 상세 조회 (주소 매핑 실패 시 기본값 제공)
    func getPostDetail(postId: String) async throws -> PostResponseEntity {
        // 1. 네트워크에서 데이터 가져오기
        let post = try await communityRepository.getPostById(postId: postId)
        
        // 2. 주소 매핑 (실패 시 기본값 제공)
        let mappedPost = await AddressMappingHelper.mapPostWithAddress(post)
        
        // 3. 결과 반환
        return mappedPost
    }
    
    // 게시글 상세 조회 (주소 매핑 실패 시 에러 발생)
    func getPostDetailExcludeFailed(postId: String) async throws -> PostResponseEntity {
        // 1. 네트워크에서 데이터 가져오기
        let post = try await communityRepository.getPostById(postId: postId)
        
        // 2. 주소 매핑 (실패 시 에러 발생)
        let geo = post.geolocation
        let address = try await addressRepository.getAddressFromGeo(geo).toShortAddress()
        
        // 3. 결과 반환
        return PostResponseEntity(
            postId: post.postId,
            category: post.category,
            title: post.title,
            content: post.content,
            geolocation: post.geolocation,
            creator: post.creator,
            files: post.files,
            comments: post.comments,
            createdAt: post.createdAt,
            updatedAt: post.updatedAt,
            isLike: post.isLike,
            likeCount: post.likeCount,
            address: address
        )
    }
    
    // 게시글 좋아요 토글
    func toggleLike(postId: String, status: Bool) async throws -> LikeEstateEntity {
        return try await communityRepository.likePost(postId: postId, status: status)
    }
    
    // 댓글 작성
    func postComment(postId: String, content: String, parentCommentId: String? = nil) async throws -> CommentResponseEntity {
        let commentRequest = PostCommentRequestDTO(
            parent_comment_id: parentCommentId,
            content: content
        )
        return try await communityRepository.postComment(postId: postId, comment: commentRequest)
    }
    // 게시글 삭제
    func deletePost(postId: String) async throws -> Bool {
        return try await communityRepository.deletePost(postId: postId)
    }

    // 게시글 수정 (주소 매핑 실패 시 에러 발생)
    func editPost(postId: String, posting: EditPostRequestDTO) async throws -> PostResponseEntity {
        // 1. 게시글 수정
        let post = try await communityRepository.editPost(postId: postId, posting: posting)
        // 2. 주소 매핑 (실패 시 에러 발생)
        let geo = post.geolocation
        let address = try await addressRepository.getAddressFromGeo(geo).toShortAddress()
        // 3. 결과 반환
        return PostResponseEntity(
            postId: post.postId,
            category: post.category,
            title: post.title,
            content: post.content,
            geolocation: post.geolocation,
            creator: post.creator,
            files: post.files,
            comments: post.comments,
            createdAt: post.createdAt,
            updatedAt: post.updatedAt,
            isLike: post.isLike,
            likeCount: post.likeCount,
            address: address
        )
    }

    // 댓글 수정
    func editComment(postId: String, commentId: String, comment: EditCommentRequestDTO) async throws -> CommentResponseEntity {
        return try await communityRepository.editComment(postId: postId, commentId: commentId, comment: comment)
    }

    // 댓글 삭제
    func deleteComment(postId: String, commentId: String) async throws -> Bool {
        return try await communityRepository.deleteComment(postId: postId, commentId: commentId)
    }

    // 게시글 작성
    func posting(dto: PostRequestDTO) async throws -> PostResponseEntity {
        return try await communityRepository.postPosting(posting: dto)
    }
}
