import Foundation

// MARK: - CommunityNetworkRepository Factory
internal enum CommunityNetworkRepositoryFactory {
    static func create() -> CommunityNetworkRepository {
        return CommunityNetworkRepositoryImp()
    }
}

// MARK: - CommunityNetworkRepository Implementation
internal final class CommunityNetworkRepositoryImp: CommunityNetworkRepository {

    func postFile(files: [FileData]) async throws -> [FileEntity] {
        do {
            let response = try await NetworkManager.shared.callRequest(target: CommunityRouter.postFile(files: files), model: FileDTO.self)
            return response.toEntity()
        } catch {
            throw error
        }
    }
    
    func postPosting(posting: PostRequestDTO) async throws -> PostResponseEntity {
        do {
            let response = try await NetworkManager.shared.callRequest(target: CommunityRouter.posting(dto: posting), model: PostResponseDTO.self)
            guard let entity = response.toEntity() else {
                throw CustomError.nilResponse
            }
            return entity
        } catch {
            throw error
        }
    }
    
    func getLocationPost(category: String?, latitude: Double?, longitude: Double?, maxDistance: Double?, next: String?, order: String?) async throws -> PostSummaryPaginationResponseEntity {
        do {
            let response = try await NetworkManager.shared.callRequest(target: CommunityRouter.getLocationPost(category: category, longitude: String(longitude ?? 0), latitude: String(latitude ?? 0), maxDistance: String(maxDistance ?? 0), next: next, order: order), model: PostSummaryPaginationResponseDTO.self)
            guard let entity = response.toEntity() else {
                throw CustomError.nilResponse
            }
            return entity
        } catch {
            throw error
        }
    }
    
    func searchPostByTitle(title: String) async throws -> PostSummaryListResponseEntity {
        do {
            let response = try await NetworkManager.shared.callRequest(target: CommunityRouter.searchPostTitle(title: title), model: PostSummaryListResponseDTO.self)
            guard let entity = response.toEntity() else {
                throw CustomError.nilResponse
            }
            return entity
        } catch {
            throw error
        }
    }
    
    func searchPostById(postId: String) async throws -> PostResponseEntity {
        do {
            let response = try await NetworkManager.shared.callRequest(target: CommunityRouter.searchPost(post_id: postId), model: PostResponseDTO.self)
            guard let entity = response.toEntity() else {
                throw CustomError.nilResponse
            }
            return entity
        } catch {
            throw error
        }
    }
    
    func editPost(postId: String, posting: EditPostRequestDTO) async throws -> PostResponseEntity {
        do {
            let response = try await NetworkManager.shared.callRequest(target: CommunityRouter.editPost(post_id: postId, dto: posting), model: PostResponseDTO.self)
            guard let entity = response.toEntity() else {
                throw CustomError.nilResponse
            }
            return entity
        } catch {
            throw error
        }
    }
    
    func deletePost(postId: String) async throws -> Bool {
        do {
            let _: EmptyResponseDTO = try await NetworkManager.shared.callRequest(
                target: CommunityRouter.deletePost(post_id: postId),
                model: EmptyResponseDTO.self
            )
            return true // 성공 시 true 반환
        } catch {
            throw error
        }
    }
    
    func likePost(postId: String) async throws -> LikeEstateEntity {
        do {
            let response = try await NetworkManager.shared.callRequest(target: CommunityRouter.likePost(post_id: postId, dto: LikeEstateRequestDTO(likeStatus: true)), model: LikeEstateResponseDTO.self)
            guard let entity = response.toEntity() else {
                throw CustomError.nilResponse
            }
            return entity
        } catch {
            throw error
        }
    }
    
    func searchPostByUserId(userId: String) async throws -> PostSummaryPaginationResponseEntity {
        do {
            let response = try await NetworkManager.shared.callRequest(target: CommunityRouter.searchUserPost(user_id: userId), model: PostSummaryPaginationResponseDTO.self)
            guard let entity = response.toEntity() else {
                throw CustomError.nilResponse
            }
            return entity
        } catch {
            throw error
        }
    }
    
    func searchPostByMyLike() async throws -> PostSummaryPaginationResponseEntity {
        do {
            let response = try await NetworkManager.shared.callRequest(target: CommunityRouter.searchMyLikePost, model: PostSummaryPaginationResponseDTO.self)
            guard let entity = response.toEntity() else {
                throw CustomError.nilResponse
            }
            return entity
        } catch {
            throw error
        }
    }
    
    func postComment(postId: String, comment: PostCommentRequestDTO) async throws -> CommentResponseEntity {
        do {
            let response = try await NetworkManager.shared.callRequest(target: CommunityRouter.postComment(post_id: postId, dto: comment), model: CommentResponseDTO.self)
            guard let entity = response.toEntity() else {
                throw CustomError.nilResponse
            }
            return entity
        } catch {
            throw error
        }
    }
    
    func editComment(postId: String, commentId: String, comment: EditCommentRequestDTO) async throws -> CommentResponseEntity {
        do {
            let response = try await NetworkManager.shared.callRequest(target: CommunityRouter.editComment(post_id: postId, comment_id: commentId, dto: comment), model: CommentResponseDTO.self)
            guard let entity = response.toEntity() else {
                throw CustomError.nilResponse
            }
            return entity
        } catch {
            throw error
        }
    }
    
    func deleteComment(postId: String, commentId: String) async throws -> Bool {
        do {
            let _: EmptyResponseDTO = try await NetworkManager.shared.callRequest(
                target: CommunityRouter.deleteComment(post_id: postId, comment_id: commentId),
                model: EmptyResponseDTO.self
            )
            return true // 성공 시 true 반환
        } catch {
            throw error
        }
    }


}
