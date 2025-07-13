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
            print("📍 CommunityNetworkRepositoryImp: 게시글 수: \(entity.data.count)")
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
    
    func getPostById(postId: String) async throws -> PostResponseEntity {
        do {
            let response = try await NetworkManager.shared.callRequest(target: CommunityRouter.getPost(post_id: postId), model: PostResponseDTO.self)
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
            // 빈 응답을 처리하기 위해 Data로 직접 받아서 처리
            let request = try CommunityRouter.deletePost(post_id: postId).asURLRequest()
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // HTTP 상태 코드 확인
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CustomError.unknown(code: -1, message: "유효하지 않은 응답입니다.")
            }
            
            // 200 성공 응답인지 확인
            guard httpResponse.statusCode == 200 else {
                throw CustomError.from(code: httpResponse.statusCode, router: "CommunityRouter")
            }
            
            // 응답 데이터가 비어있거나 유효하지 않은 JSON이어도 성공으로 처리
            return true
        } catch {
            throw error
        }
    }
    
    func likePost(postId: String, status: Bool) async throws -> LikeEstateEntity {
        do {
            let response = try await NetworkManager.shared.callRequest(target: CommunityRouter.likePost(post_id: postId, dto: LikeEstateRequestDTO(likeStatus: status)), model: LikeEstateResponseDTO.self)
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
            // 빈 응답을 처리하기 위해 Data로 직접 받아서 처리
            let request = try CommunityRouter.deleteComment(post_id: postId, comment_id: commentId).asURLRequest()
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // HTTP 상태 코드 확인
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CustomError.unknown(code: -1, message: "유효하지 않은 응답입니다.")
            }
            
            // 200 성공 응답인지 확인
            guard httpResponse.statusCode == 200 else {
                throw CustomError.from(code: httpResponse.statusCode, router: "CommunityRouter")
            }
            
            // 응답 데이터가 비어있거나 유효하지 않은 JSON이어도 성공으로 처리
            return true
        } catch {
            throw error
        }
    }


}
