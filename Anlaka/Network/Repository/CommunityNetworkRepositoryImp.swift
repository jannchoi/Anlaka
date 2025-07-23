import Foundation



internal final class CommunityNetworkRepositoryImp {

    func postFile(files: [FileData]) async throws -> FileEntity { 
        do {
            let response = try await NetworkManager.shared.callRequest(target: .CommunityRouter.postFile, model:FileDTO.self)
            guard let entity = response.toEntity() else {
                throw NetworkError.nilResponse
            }
            return entity
        } catch {
            throw error

        }
    }
    func postPosting(posting: PostRequestDTO) async throws -> PostResponseEntity {
        do {
            let response = try await NetworkManager.shared.callRequest(target: .CommunityRouter.posting, model: PostResponseDTO.self)
            guard let entity = response.toEntity() else {
                throw NetworkError.nilResponse
            }
            return entity
        } catch {
            throw error
        }
    }
    func getLocationPost(category: String?, latitude: Double?, longitude: Double?, maxDistance: Double?, next: String?, order: String?) async throws -> PostSummaryPaginationResponseEntity {
        do {
            let response = try await NetworkManager.shared.callRequest(target: .CommunityRouter.getLocationPost, model: PostSummaryPaginationResponseDTO.self)
            guard let entity = response.toEntity() else {
                throw NetworkError.nilResponse
            }
            return entity
        } catch {
            throw error
        }
    }
    func searchPostByTitle(title: String) async throws -> PostSummaryListResponseEntity {
        do {
            let response = try await NetworkManager.shared.callRequest(target: .CommunityRouter.searchPostTitle, model: PostSummaryListResponseDTO.self)
            guard let entity = response.toEntity() else {
                throw NetworkError.nilResponse
            }
            return entity
        } catch {
            throw error
        }
    }
    func searchPostById(postId: String) async throws -> PostResponseEntity {
        do {
            let response = try await NetworkManager.shared.callRequest(target: .CommunityRouter.searchPost, model: PostResponseDTO.self)
            guard let entity = response.toEntity() else {
                throw NetworkError.nilResponse
            }
            return entity
        } catch {
            throw error
        }
    }
    func editPost(postId: String, posting: PostRequestDTO) async throws -> PostResponseEntity {
        do {
            let response = try await NetworkManager.shared.callRequest(target: .CommunityRouter.editPost, model: PostResponseDTO.self)
            guard let entity = response.toEntity() else {
                throw NetworkError.nilResponse
            }
            return entity
        } catch {
            throw error
        }
    }
    func deletePost(postId: String) async throws -> Bool {
        do {
            let _: EmptyResponseDTO = try await NetworkManager.shared.callRequest(
                target: .CommunityRouter.deletePost(post_id: postId), 
                model: EmptyResponseDTO.self
            )
            return true // 성공 시 true 반환
        } catch {
            throw error
        }
    }
    func likePost(postId: String) async throws -> LikeEstateEntity {
        do {
            let response = try await NetworkManager.shared.callRequest(target: .CommunityRouter.likePost, model: LikeEstateResponseDTO.self)
            guard let entity = response.toEntity() else {
                throw NetworkError.nilResponse
            }
            return entity
        } catch {
            throw error
        }
    }
    func searchPostByUserId(userId: String) async throws -> PostSummaryPaginationResponseEntity {
        do {
            let response = try await NetworkManager.shared.callRequest(target: .CommunityRouter.searchUserPost, model: PostSummaryPaginationResponseDTO.self)
            guard let entity = response.toEntity() else {
                throw NetworkError.nilResponse
            }
            return entity
        } catch {
            throw error
        }
    }
    func searchPostByMyLike() async throws -> PostSummaryPaginationResponseEntity {
        do {
            let response = try await NetworkManager.shared.callRequest(target: .CommunityRouter.searchMyLikePost, model: PostSummaryPaginationResponseDTO.self)
            guard let entity = response.toEntity() else {
                throw NetworkError.nilResponse
            }
            return entity
        } catch {
            throw error
        }
    }
    func postComment(postId: String, comment: PostCommentRequestDTO) async throws -> CommentResponseEntity {
        do {
            let response = try await NetworkManager.shared.callRequest(target: .CommunityRouter.postComment, model: CommentResponseDTO.self)
            guard let entity = response.toEntity() else {
                throw NetworkError.nilResponse
            }
            return entity
        } catch {
            throw error
        }
    }
    func editComment(postId: String, commentId: String, comment: EditCommentRequestDTO) async throws -> CommentResponseEntity {
        do {
            let response = try await NetworkManager.shared.callRequest(target: .CommunityRouter.editComment, model: CommentResponseDTO.self)
            guard let entity = response.toEntity() else {
                throw NetworkError.nilResponse
            }
            return entity
        } catch {
            throw error
        }
    }
    func deleteComment(postId: String, commentId: String) async throws -> Bool {
        do {
            let _: EmptyResponseDTO = try await NetworkManager.shared.callRequest(
                target: .CommunityRouter.deleteComment(post_id: postId, comment_id: commentId), 
                model: EmptyResponseDTO.self
            )
            return true // 성공 시 true 반환
        } catch {
            throw error
        }
    }


}