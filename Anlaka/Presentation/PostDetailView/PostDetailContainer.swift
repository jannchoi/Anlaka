
import Foundation

struct PostDetailModel {
    var post: PostResponseEntity?
    var isLoading: Bool = false
    var error: String? = nil
    var isLiked: Bool = false
    var likeCount: Int = 0
    var isSendingComment: Bool = false // 댓글 전송 중 상태 추가
    var toast: FancyToast? = nil // toast 메시지 추가
}

enum PostDetailIntent {
    case initialRequest
    case toggleLike
    case sendComment(String)
    case sendReply(String, String) // commentId, content
    case resendComment(String) // tempId
    case resendReply(String, String) // parentCommentId, tempId
    case deleteTempComment(String) // tempId
    case deleteTempReply(String, String) // parentCommentId, tempId
    case editComment(String, String) // commentId, newContent
    case editReply(String, String, String) // parentCommentId, replyId, newContent
    case deleteComment(String) // commentId
    case deleteReply(String, String) // parentCommentId, replyId
    case deletePost // 게시글 삭제 추가
}

@MainActor
final class PostDetailContainer: ObservableObject {
    @Published var model = PostDetailModel()
    private let useCase: PostingUseCase
    private let postId: String
    
    init(useCase: PostingUseCase, postId: String) {
        self.useCase = useCase
        self.postId = postId
    }
    
    func handle(_ intent: PostDetailIntent) {
        switch intent {
        case .initialRequest:
            Task {
                await loadInitialData(postId: postId)
            }
        case .toggleLike:
            Task {
                await toggleLike()
            }
        case .sendComment(let content):
            Task {
                await sendComment(content: content)
            }
        case .sendReply(let commentId, let content):
            Task {
                await sendReply(commentId: commentId, content: content)
            }
        case .resendComment(let tempId):
            Task {
                await resendComment(tempId: tempId)
            }
        case .resendReply(let parentCommentId, let tempId):
            Task {
                await resendReply(parentCommentId: parentCommentId, tempId: tempId)
            }
        case .deleteTempComment(let tempId):
            deleteTempComment(tempId: tempId)
        case .deleteTempReply(let parentCommentId, let tempId):
            deleteTempReply(parentCommentId: parentCommentId, tempId: tempId)
        case .editComment(let commentId, let newContent):
            Task {
                await editComment(commentId: commentId, newContent: newContent)
            }
        case .editReply(let parentCommentId, let replyId, let newContent):
            Task {
                await editReply(parentCommentId: parentCommentId, replyId: replyId, newContent: newContent)
            }
        case .deleteComment(let commentId):
            Task {
                await deleteComment(commentId: commentId)
            }
        case .deleteReply(let parentCommentId, let replyId):
            Task {
                await deleteReply(parentCommentId: parentCommentId, replyId: replyId)
            }
        case .deletePost:
            Task {
                await deletePost()
            }
        }
    }
    
    private func loadInitialData(postId: String) async {
        model.isLoading = true
        defer { model.isLoading = false }
        
        do {
            let post = try await useCase.getPostDetail(postId: postId)
            model.post = post
            model.isLiked = post.isLike
            model.likeCount = post.likeCount
        } catch {
            model.error = error.localizedDescription
        }
    }
    
    private func toggleLike() async {
        // UI 먼저 토글
        let prevLiked = model.isLiked
        let prevLikeCount = model.likeCount
        model.isLiked.toggle()
        model.likeCount += model.isLiked ? 1 : -1
        
        // 게시글 데이터도 업데이트
        model.post?.isLike = model.isLiked
        model.post?.likeCount = model.likeCount
        
        do {
            try await useCase.toggleLike(postId: postId, status: model.isLiked)
        } catch {
            // 실패 시 롤백 및 에러 메시지 저장
            model.isLiked = prevLiked
            model.likeCount = prevLikeCount
            model.post?.isLike = prevLiked
            model.post?.likeCount = prevLikeCount
            model.error = error.localizedDescription
        }
    }
    
    private func sendComment(content: String) async {
        
        guard var post = model.post, let user = UserDefaultsManager.shared.getObject(forKey: .profileData, as: MyProfileInfoEntity.self) else { return }
        model.isSendingComment = true
        defer { model.isSendingComment = false }
        
        let tempId = UUID().uuidString
        let creator = user
        let now = ISO8601DateFormatter().string(from: Date())
        var tempComment = PostCommentResponseEntity(
            commentId: tempId,
            content: content,
            createdAt: now,
            creator: user.toUserInfoEntity(),
            replies: [],
            sendFailed: false,
            isTemp: true,
            tempId: tempId
        )
        post.comments.append(tempComment)
        model.post = post
        // 댓글 추가 시 댓글 수 업데이트 필요 없음
        
        do {
            let result = try await useCase.postComment(postId: postId, content: content, parentCommentId: nil)
            // 서버 응답으로 교체 (CommentResponseEntity → PostCommentResponseEntity 변환)
            if let idx = model.post?.comments.firstIndex(where: { $0.tempId == tempId }) {
                model.post?.comments[idx] = result.toPostCommentEntity()
            }
        } catch {
            // 실패 시 sendFailed = true
            if let idx = model.post?.comments.firstIndex(where: { $0.tempId == tempId }) {
                model.post?.comments[idx].sendFailed = true
            }
            model.error = error.localizedDescription
        }
    }
    
    private func sendReply(commentId: String, content: String) async {
        guard var post = model.post, let user = UserDefaultsManager.shared.getObject(forKey: .profileData, as: MyProfileInfoEntity.self) else { return }
        
        model.isSendingComment = true
        defer { model.isSendingComment = false }
        
        let tempId = UUID().uuidString
        let now = ISO8601DateFormatter().string(from: Date())
        var tempReply = CommentResponseEntity(
            commentId: tempId,
            content: content,
            createdAt: now,
            creator: user.toUserInfoEntity(),
            geolocation: nil,
            replies: nil,
            sendFailed: false,
            isTemp: true,
            tempId: tempId
        )
        if let idx = post.comments.firstIndex(where: { $0.commentId == commentId }) {
            var comment = post.comments[idx]
            var replies = comment.replies
            replies.append(tempReply)
            comment.replies = replies
            post.comments[idx] = comment
            model.post = post
        }
        do {
            let result = try await useCase.postComment(postId: postId, content: content, parentCommentId: commentId)
            // 서버 응답을 CommentResponseEntity로 변환 필요 (이미 CommentResponseEntity 타입)
            if let cIdx = model.post?.comments.firstIndex(where: { $0.commentId == commentId }) {
                if let rIdx = model.post?.comments[cIdx].replies.firstIndex(where: { $0.tempId == tempId }) {
                    model.post?.comments[cIdx].replies[rIdx] = result
                }
            }
        } catch {
            if let cIdx = model.post?.comments.firstIndex(where: { $0.commentId == commentId }) {
                if let rIdx = model.post?.comments[cIdx].replies.firstIndex(where: { $0.tempId == tempId }) {
                    model.post?.comments[cIdx].replies[rIdx].sendFailed = true
                }
            }
            model.error = error.localizedDescription
        }
    }
    
    private func resendComment(tempId: String) async {
        guard let idx = model.post?.comments.firstIndex(where: { $0.tempId == tempId }), let comment = model.post?.comments[idx] else { return }
        do {
            let result = try await useCase.postComment(postId: postId, content: comment.content, parentCommentId: nil)
            model.post?.comments[idx] = result.toPostCommentEntity()
        } catch {
            model.post?.comments[idx].sendFailed = true
            model.error = error.localizedDescription
        }
    }
    
    private func resendReply(parentCommentId: String, tempId: String) async {
        guard let cIdx = model.post?.comments.firstIndex(where: { $0.commentId == parentCommentId }), let rIdx = model.post?.comments[cIdx].replies.firstIndex(where: { $0.tempId == tempId }), let reply = model.post?.comments[cIdx].replies[rIdx] else { return }
        do {
            let result = try await useCase.postComment(postId: postId, content: reply.content, parentCommentId: parentCommentId)
            model.post?.comments[cIdx].replies[rIdx] = result
        } catch {
            model.post?.comments[cIdx].replies[rIdx].sendFailed = true
            model.error = error.localizedDescription
        }
    }
    
    private func deleteTempComment(tempId: String) {
        model.post?.comments.removeAll { $0.tempId == tempId }
    }
    
    private func deleteTempReply(parentCommentId: String, tempId: String) {
        guard let cIdx = model.post?.comments.firstIndex(where: { $0.commentId == parentCommentId }) else { return }
        model.post?.comments[cIdx].replies.removeAll { $0.tempId == tempId }
    }
    
    private func editComment(commentId: String, newContent: String) async {
        guard var post = model.post, let idx = post.comments.firstIndex(where: { $0.commentId == commentId }) else { return }
        let oldContent = post.comments[idx].content
        post.comments[idx].content = newContent
        model.post = post
        do {
            let editRequest = EditCommentRequestDTO(content: newContent)
            try await useCase.editComment(postId: postId, commentId: commentId, comment: editRequest)
        } catch {
            // 실패 시 롤백 및 sendFailed
            model.post?.comments[idx].content = oldContent
            model.post?.comments[idx].sendFailed = true
            model.error = error.localizedDescription
        }
    }
    
    private func editReply(parentCommentId: String, replyId: String, newContent: String) async {
        guard var post = model.post, let cIdx = post.comments.firstIndex(where: { $0.commentId == parentCommentId }), let rIdx = post.comments[cIdx].replies.firstIndex(where: { $0.commentId == replyId }) else { return }
        let oldContent = post.comments[cIdx].replies[rIdx].content
        post.comments[cIdx].replies[rIdx].content = newContent
        model.post = post
        do {
            let editRequest = EditCommentRequestDTO(content: newContent)
            try await useCase.editComment(postId: postId, commentId: replyId, comment: editRequest)
        } catch {
            // 실패 시 롤백 및 sendFailed
            model.post?.comments[cIdx].replies[rIdx].content = oldContent
            model.post?.comments[cIdx].replies[rIdx].sendFailed = true
            model.error = error.localizedDescription
        }
    }
    
    private func deleteComment(commentId: String) async {
        guard let idx = model.post?.comments.firstIndex(where: { $0.commentId == commentId }) else { return }
        let deletedComment = model.post?.comments.remove(at: idx)
        do {
            let success = try await useCase.deleteComment(postId: postId, commentId: commentId)
            print(success, "=========")
            // 댓글 삭제 성공 시 별도 카운트 업데이트 필요 없음
        } catch {
            // 실패 시 복구 및 sendFailed
            if let deletedComment = deletedComment {
                model.post?.comments.insert(deletedComment, at: idx)
                model.post?.comments[idx].sendFailed = true
            }
            model.error = error.localizedDescription
        }
    }
    
    private func deleteReply(parentCommentId: String, replyId: String) async {
        guard let cIdx = model.post?.comments.firstIndex(where: { $0.commentId == parentCommentId }), let rIdx = model.post?.comments[cIdx].replies.firstIndex(where: { $0.commentId == replyId }) else { return }
        let deleted = model.post?.comments[cIdx].replies.remove(at: rIdx)
        do {
            try await useCase.deleteComment(postId: postId, commentId: replyId)
            // 답글 삭제 성공 시 별도 카운트 업데이트 필요 없음
        } catch {
            // 실패 시 복구 및 sendFailed
            if let deleted = deleted {
                model.post?.comments[cIdx].replies.insert(deleted, at: rIdx)
                model.post?.comments[cIdx].replies[rIdx].sendFailed = true
            }
            model.error = error.localizedDescription
        }
    }
    
    private func deletePost() async {
        guard let post = model.post else { return }
        do {
            try await useCase.deletePost(postId: postId)
            // 게시글 삭제 성공 시 toast 표시 후 화면 이동
            model.toast = FancyToast(
                type: .success,
                title: "성공",
                message: "게시글이 삭제되었습니다.",
                duration: 2.0
            )
            // 1.2초 후 모델 초기화하여 화면 이동
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                self.model.post = nil
                self.model.error = nil
            }
        } catch {
            model.error = error.localizedDescription
        }
    }
}
