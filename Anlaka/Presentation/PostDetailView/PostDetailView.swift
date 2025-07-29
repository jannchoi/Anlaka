import SwiftUI

// 전역 함수로 isMine 이동
func isMine(_ userId: String) -> Bool {
    guard let userInfo = UserDefaultsManager.shared.getObject(forKey: .profileData, as: MyProfileInfoEntity.self) else { return false }
    return userId == userInfo.userid
}

struct PostDetailView: View {
    @StateObject private var container: PostDetailContainer
    @State private var commentText: String = ""
    @State private var selectedReplyCommentId: String? = nil
    @Binding var path: NavigationPath
    // Toast 상태 추가
    @State private var toast: FancyToast? = nil
    // CustomAlert 상태 추가
    @State private var customAlert: CustomAlert? = nil
    // 메뉴 스타일 Picker 상태 및 처리 추가
    @State private var actionSelection: String? = nil
    @State private var isProcessing = false
    // 키보드 응답자 추가
    @StateObject private var keyboard = KeyboardResponder()
    // ChatInputView 포커스 상태 추가
    @FocusState private var isChatInputFocused: Bool
    // 댓글/대댓글 수정 모드 추적
    @State private var editingCommentId: String? = nil
    @State private var editingReplyId: String? = nil
    let di: DIContainer // di 추가
    
    init(postId: String, di: DIContainer, path: Binding<NavigationPath>) {
        self._path = path
        self.di = di // di 저장
        _container = StateObject(wrappedValue: di.makePostDetailContainer(postId: postId))
    }
    
    var body: some View {
        ZStack {
            Color.WarmLinen
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // CustomNavigationBar
                CustomNavigationBar(
                    title: "정보",
                    leftButton: {
                        Button(action: {
                            if !path.isEmpty {
                                path.removeLast()
                            }
                        }) {
                            Image("chevron")
                                .font(.headline)
                                .foregroundColor(.MainTextColor)
                        }
                    },
                    rightButton: {
                        Button(action: {
                            container.handle(.toggleLike)
                        }) {
                            Image(container.model.post?.isLike == true ? "Like_Fill" : "Like_Empty")
                                .font(.title2)
                                .foregroundColor(container.model.post?.isLike == true ? Color.OliveMist : Color.Deselected)
                        }
                    }
                )
                
                // 스크롤 가능한 컨텐츠
                if let post = container.model.post {
                    ScrollView {
                        VStack(spacing: 0) {
                            // 게시글 섹션 (흰색 배경)
                            VStack(spacing: 12) {
                                // 카테고리 태그
                                categoryTag(post: post)
                                
                                // 사용자 정보 뷰
                                userDataView(post: post)
                                
                                // 제목
                                titleView(post: post)
                                
                                // 내용
                                contentView(post: post)
                                
                                // 파일들
                                filesView(post: post)
                                
                                // 좋아요, 댓글 수
                                engagementView(post: post)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            
                            // 구분선
                            Divider()
                                .background(Color.Gray60)
                                .padding(.horizontal, 12)
                            
                            // 댓글 섹션 (흰색 배경)
                            commentsSection(post: post)
                                .background(Color.white)
                        }
                        .padding(.bottom, 100) // ChatInputView 높이만큼 여백
                    }
                } else if container.model.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Text("게시글을 불러올 수 없습니다.")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                Spacer()
            }
            
            // 하단 고정 ChatInputView (수정 모드가 아닐 때만 표시)
            if editingCommentId == nil && editingReplyId == nil {
                // 디버깅용 로그
                let _ = print("ChatInputView 표시됨 - editingCommentId: \(editingCommentId ?? "nil"), editingReplyId: \(editingReplyId ?? "nil")")
                VStack(spacing: 0) {
                    Spacer()
                    
                    // 답글 입력 모드일 때
                    if let selectedReplyCommentId = selectedReplyCommentId {
                        VStack(spacing: 8) {
                            HStack {
                                Text("답글 작성 중...")
                                    .font(.pretendardCaption)
                                    .foregroundColor(Color.Gray60)
                                Spacer()
                                Button("취소") {
                                    self.selectedReplyCommentId = nil
                                }
                                .font(.pretendardCaption)
                                .foregroundColor(Color.TomatoRed)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            
                            ChatInputView(
                                text: $commentText,
                                selectedFiles: .constant([]),
                                invalidFileIndices: Set<Int>(),
                                onSend: {
                                    guard !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                                    let replyText = commentText
                                    self.commentText = ""
                                    sendReply(parentCommentId: selectedReplyCommentId, content: replyText)
                                    self.selectedReplyCommentId = nil
                                },
                                onImagePicker: {},
                                onDocumentPicker: {},
                                isSending: container.model.isSendingComment,
                                showFileUpload: false
                            )
                            .padding(.horizontal, 8)
                            .padding(.top, 8)
                            .disabled(container.model.isSendingComment)
                        }
                    } else {
                        // 일반 댓글 입력
                        ChatInputView(
                            text: $commentText,
                            selectedFiles: .constant([]), // 댓글에서는 파일 업로드 불가
                            invalidFileIndices: Set<Int>(),
                            onSend: sendComment,
                            onImagePicker: {},
                            onDocumentPicker: {},
                            isSending: container.model.isSendingComment,
                            showFileUpload: false
                        )
                        .padding(.horizontal, 8)
                        .padding(.top, 8)
                        .padding(.bottom)
                        .background(Color.white)
                        .disabled(container.model.isSendingComment)
                        
                    }
                }

                
                
            }
            
            // 서버 응답 대기 중 interaction disable 및 ProgressView 오버레이
            if isProcessing {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
        .disabled(isProcessing)
        .onAppear {
            container.handle(.initialRequest)
            CurrentScreenTracker.shared.setCurrentScreen(.posting)
        }
        // Toast 적용
        .toastView(toast: $toast)
        // CustomAlertView 적용
        .customAlertView(alert: $customAlert)
        // 키보드 내리기 툴바 적용
        .dismissKeyboardToolbar()
        // model.error가 발생하면 toast로 안내
        .onChange(of: container.model.error) { error in
            if let error = error {
                toast = FancyToast(type: .error, title: "오류", message: error, duration: 2)
                container.model.error = nil
            }
        }
        // model.toast가 설정되면 toast로 표시
        .onChange(of: container.model.toast) { newToast in
            if let newToast = newToast {
                toast = newToast
                container.model.toast = nil
            }
        }
        // 게시글 삭제 성공 시 화면 닫기
        .onChange(of: container.model.post) { post in
            if post == nil {
                // 게시글이 삭제되었으면 이전 화면으로 돌아가기
                if !path.isEmpty {
                    path.removeLast()
                }
            }
        }
        .navigationDestination(for: AppRoute.PostDetailRoute.self) { route in
            switch route {
            case .posting(let post):
                PostingView(post: post, di: di, path: $path)
            }
        }
        // 기존 .alertViews() 제거
    }
    
    // MARK: - Category Tag
    private func categoryTag(post: PostResponseEntity) -> some View {
        HStack {
            Text(post.category)
                .font(.soyoBody)
                .foregroundColor(Color.Gray60)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.TagBackground)
                .cornerRadius(4)
            Spacer()
        }
        .padding(.top, 16)
    }
    
    // MARK: - User Data View
    private func userDataView(post: PostResponseEntity) -> some View {
        HStack(spacing: 12) {
            // 프로필 이미지
            CustomAsyncImage(imagePath: post.creator.profileImage)
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(post.creator.nick)
                    .font(.soyoSubheadline)
                    .foregroundColor(Color.MainTextColor)
                
                HStack(spacing: 4) {
                    Text(post.address)
                        .font(.pretendardCaption)
                        .foregroundColor(Color.Gray60)
                    
                    Text("•")
                        .font(.pretendardCaption)
                        .foregroundColor(Color.Gray60)
                    
                    Text(PresentationMapper.formatRelativeTime(post.createdAt))
                        .font(.pretendardCaption)
                        .foregroundColor(Color.Gray60)
                }
            }
            
            Spacer()
            
            // 연필 버튼 + 메뉴 스타일 Picker (게시글 작성자인 경우에만 표시)
            if isMine(post.creator.userId) {
                Menu {
                    Button("수정하기") {
                        actionSelection = "edit"
                    }
                    Button("삭제하기", role: .destructive) {
                        actionSelection = "delete"
                    }
                } label: {
                    Image(systemName: "pencil")
                        .foregroundColor(.MainTextColor)
                        .font(.system(size: 16))
                }
                .padding(.trailing, 12)
            }
        }
        .padding(.vertical, 8)
        .onChange(of: actionSelection) { newValue in
            guard let action = newValue, let post = container.model.post else { return }
            if action == "edit" {
                // path에 AppRoute 추가
                path.append(AppRoute.PostDetailRoute.posting(post: post))
            } else if action == "delete" {
                container.handle(.deletePost)
            }
            actionSelection = nil
        }
    }
    
    // MARK: - Title View
    private func titleView(post: PostResponseEntity) -> some View {
        HStack {
            Text(post.title)
                .font(.soyoTitle3)
                .foregroundColor(Color.MainTextColor)
                .multilineTextAlignment(.leading)
            Spacer()
        }
    }
    
    // MARK: - Content View
    private func contentView(post: PostResponseEntity) -> some View {
        HStack {
            Text(post.content)
                .font(.pretendardSubheadline)
                .foregroundColor(Color.MainTextColor)
                .multilineTextAlignment(.leading)
            Spacer()
        }
    }
    
    // MARK: - Files View
    private func filesView(post: PostResponseEntity) -> some View {
        Group {
            if !post.files.isEmpty {
                VStack(spacing: 8) {
                    ForEach(post.files, id: \.serverPath) { file in
                        CustomAsyncImage.detail(imagePath: file.serverPath)
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .cornerRadius(8)
                    }   
                }
            }
        }
    }
    
    // MARK: - Engagement View
    private func engagementView(post: PostResponseEntity) -> some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: "heart")
                    .font(.caption)
                    .foregroundColor(Color.Gray60)
                
                Text("\(post.likeCount)")
                    .font(.pretendardFootnote)
                    .foregroundColor(Color.Gray60)
            }
            
            HStack(spacing: 4) {
                Image(systemName: "bubble")
                    .font(.caption)
                    .foregroundColor(Color.Gray60)
                
                // 댓글 수 + 답글 수 계산
                let totalComments = post.comments.count + post.comments.reduce(0) { $0 + $1.replies.count }
                Text("\(totalComments)")
                    .font(.pretendardFootnote)
                    .foregroundColor(Color.Gray60)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Comments Section
    private func commentsSection(post: PostResponseEntity) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("댓글")
                .font(.pretendardFootnote)
                .foregroundColor(Color.Gray60)
                .padding(.top, 12)
                .padding(.horizontal, 12)
            
            LazyVStack(spacing: 12) {
                ForEach(post.comments, id: \.commentId) { comment in
                    CommentView(
                        comment: comment,
                        selectedReplyCommentId: $selectedReplyCommentId,
                        onReply: { commentId in
                            selectedReplyCommentId = commentId
                        },
                        onResend: { tempId in
                            showResendAlert(isReply: false, parentId: nil, tempId: tempId)
                        },
                        onDelete: { tempId in
                            showDeleteAlert(isReply: false, parentId: nil, tempId: tempId)
                        },
                        onResendReply: { parentId, tempId in
                            showResendAlert(isReply: true, parentId: parentId, tempId: tempId)
                        },
                        onDeleteReply: { parentId, tempId in
                            showDeleteAlert(isReply: true, parentId: parentId, tempId: tempId)
                        },
                        onEdit: { commentId, newContent in
                            container.handle(.editComment(commentId, newContent))
                        },
                        onDeleteComment: { commentId in
                            showDeleteAlert(isReply: false, parentId: nil, tempId: commentId)
                        },
                        onEditReply: { parentId, replyId, newContent in
                            container.handle(.editReply(parentId, replyId, newContent))
                        },
                        onDeleteReplyReal: { parentId, replyId in
                            showDeleteAlert(isReply: true, parentId: parentId, tempId: replyId)
                        },
                        editingCommentId: $editingCommentId
                    )
                }
            }
            .padding(.horizontal, 12)
            //.padding(.bottom, 12)
        }
    }
    
    // MARK: - Send Comment
    private func sendComment() {
        guard !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let commentText = self.commentText
        self.commentText = ""
        
        // 실제 댓글 전송 로직 구현
        container.handle(.sendComment(commentText))
    }
    
    // MARK: - Send Reply
    private func sendReply(parentCommentId: String, content: String) {
        container.handle(.sendReply(parentCommentId, content))
    }

    // MARK: - Alert State
    @State private var showResendAlertState: (show: Bool, isReply: Bool, parentId: String?, tempId: String?) = (false, false, nil, nil)
    @State private var showDeleteAlertState: (show: Bool, isReply: Bool, parentId: String?, tempId: String?) = (false, false, nil, nil)

    private func showResendAlert(isReply: Bool, parentId: String?, tempId: String) {
        // CustomAlert로 대체
        customAlert = CustomAlert(
            type: .info,
            title: "재전송 하시겠습니까?",
            message: "댓글을 재전송하시겠습니까?",
            primaryButtonTitle: "재전송",
            secondaryButtonTitle: "취소",
            onPrimary: {
                if isReply {
                    if let parentId = parentId {
                        container.handle(.resendReply(parentId, tempId))
                    }
                } else {
                    container.handle(.resendComment(tempId))
                }
                toast = FancyToast(type: .info, title: "재전송", message: "재전송을 시도합니다.", duration: 2)
            },
            onSecondary: {
                // 취소시 아무 동작 없음
            }
        )
    }
    private func showDeleteAlert(isReply: Bool, parentId: String?, tempId: String) {
        // CustomAlert로 대체
        customAlert = CustomAlert(
            type: .error,
            title: "삭제 하시겠습니까?",
            message: "댓글을 삭제하시겠습니까?",
            primaryButtonTitle: "삭제",
            secondaryButtonTitle: "취소",
            onPrimary: {
                if isReply {
                    if let parentId = parentId {
                        // tempId가 실제 replyId로 사용됨
                        container.handle(.deleteReply(parentId, tempId))
                    }
                } else {
                    // tempId가 실제 commentId로 사용됨
                    container.handle(.deleteComment(tempId))
                }
                toast = FancyToast(type: .info, title: "삭제", message: "삭제되었습니다.", duration: 2)
            },
            onSecondary: {
                // 취소시 아무 동작 없음
            }
        )
    }
}

// MARK: - Comment View
struct CommentView: View {
    let comment: PostCommentResponseEntity
    @Binding var selectedReplyCommentId: String?
    let onReply: (String) -> Void
    let onResend: (String) -> Void
    let onDelete: (String) -> Void
    let onResendReply: (String, String) -> Void
    let onDeleteReply: (String, String) -> Void
    let onEdit: (String, String) -> Void
    let onDeleteComment: (String) -> Void
    let onEditReply: (String, String, String) -> Void
    let onDeleteReplyReal: (String, String) -> Void
    @Binding var editingCommentId: String?
    
    @State private var isEditing = false
    @State private var editText = ""
    @State private var editingReplyId: String? = nil
    @State private var replyEditText = ""
    @FocusState private var isCommentTextFieldFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 메인 댓글
            HStack(alignment: .top, spacing: 12) {
                // 프로필 이미지
                CustomAsyncImage(imagePath: comment.creator.profileImage)
                    .frame(width: 35, height: 35)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    // 사용자 정보
                    VStack(alignment: .leading, spacing: 2) {
                        Text(comment.creator.nick)
                            .font(.soyoBody)
                            .foregroundColor(Color.MainTextColor)
                        
                        HStack(spacing: 4) {
                            Text(PresentationMapper.formatRelativeTime(comment.createdAt))
                                .font(.pretendardCaption2)
                                .foregroundColor(Color.Gray60)
                        }
                    }
                    // 댓글 내용 or 편집
                    if isEditing {
                        HStack {
                            TextField("댓글 수정", text: $editText)
                                .font(.pretendardFootnote)
                                .foregroundColor(Color.MainTextColor)
                                .focused($isCommentTextFieldFocused)
                            Button("저장") {
                                onEdit(comment.commentId, editText)
                                isEditing = false
                                isCommentTextFieldFocused = false
                                editingCommentId = nil
                            }
                            .font(.pretendardFootnote)
                            .foregroundColor(Color.SteelBlue)
                            Button("취소") {
                                isEditing = false
                                isCommentTextFieldFocused = false
                                editingCommentId = nil
                            }
                            .font(.pretendardFootnote)
                            .foregroundColor(Color.TomatoRed)
                        }
                        .padding(.trailing, 12)
                        .onAppear {
                            // 수정 모드가 활성화되면 포커스 설정
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isCommentTextFieldFocused = true
                            }
                        }
                    } else {
                        Text(comment.content)
                            .font(.pretendardFootnote)
                            .foregroundColor(Color.MainTextColor)
                            .multilineTextAlignment(.leading)
                    }
                    // 답글/재전송/삭제/수정 버튼
                    if comment.isTemp && comment.sendFailed {
                        HStack(spacing: 8) {
                            Button(action: { onResend(comment.tempId ?? "") }) {
                                Text("재전송").font(.pretendardFootnote).foregroundColor(Color.TomatoRed)
                            }
                            Button(action: { onDelete(comment.tempId ?? "") }) {
                                Text("삭제").font(.pretendardFootnote).foregroundColor(Color.Gray60)
                            }
                        }
                        .padding(.top, 4)
                    } else {
                        HStack(spacing: 8) {
                            Button(action: { onReply(comment.commentId) }) {
                                Text("답글").font(.pretendardFootnote).foregroundColor(Color.Gray60)
                            }
                            if isMine(comment.creator.userId) {
                                Button(action: {
                                    editText = comment.content
                                    isEditing = true
                                    editingCommentId = comment.commentId
                                    // 약간의 지연 후 포커스 설정
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        isCommentTextFieldFocused = true
                                    }
                                }) {
                                    Text("수정").font(.pretendardFootnote).foregroundColor(Color.Gray60)
                                }
                                Button(action: { onDeleteComment(comment.commentId) }) {
                                    Text("삭제").font(.pretendardFootnote).foregroundColor(Color.Gray60)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                Spacer()
            }
            // 답글이 있는 경우
            if !comment.replies.isEmpty {
                ForEach(comment.replies, id: \.commentId) { reply in
                    CommentReplyView(
                        reply: reply,
                        parentCommentId: comment.commentId,
                        onResend: onResendReply,
                        onDelete: onDeleteReply,
                        onEdit: { replyId, newContent in
                            onEditReply(comment.commentId, replyId, newContent)
                        },
                        onDeleteReal: { replyId in
                            onDeleteReplyReal(comment.commentId, replyId)
                        },
                        editingReplyId: $editingReplyId
                    )
                }
            }
        }
    }
}

// MARK: - Comment Reply View
struct CommentReplyView: View {
    let reply: CommentResponseEntity
    let parentCommentId: String
    let onResend: (String, String) -> Void
    let onDelete: (String, String) -> Void
    let onEdit: (String, String) -> Void
    let onDeleteReal: (String) -> Void
    @Binding var editingReplyId: String?
    @State private var isEditing = false
    @State private var editText = ""
    @FocusState private var isReplyTextFieldFocused: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 12) {
                // 프로필 이미지
                CustomAsyncImage(imagePath: reply.creator.profileImage)
                    .frame(width: 30, height: 30)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 4) {
                    // 사용자 정보
                    VStack(alignment: .leading, spacing: 2) {
                        Text(reply.creator.nick)
                            .font(.soyoCaption)
                            .foregroundColor(Color.MainTextColor)
                        HStack(spacing: 4) {
                            Text(PresentationMapper.formatRelativeTime(reply.createdAt))
                                .font(.pretendardCaption3)
                                .foregroundColor(Color.Gray60)
                        }
                    }
                    // 답글 내용 or 편집
                    if isEditing {
                        HStack {
                            TextField("답글 수정", text: $editText)
                                .font(.pretendardCaption)
                                .foregroundColor(Color.MainTextColor)
                                .focused($isReplyTextFieldFocused)
                            Button("저장") {
                                onEdit(reply.commentId, editText)
                                isEditing = false
                                isReplyTextFieldFocused = false
                                editingReplyId = nil
                            }
                            .font(.pretendardCaption)
                            .foregroundColor(Color.SteelBlue)
                            Button("취소") {
                                isEditing = false
                                isReplyTextFieldFocused = false
                                editingReplyId = nil
                            }
                            .font(.pretendardCaption)
                            .foregroundColor(Color.TomatoRed)
                        }
                        .padding(.trailing, 12)
                        .onAppear {
                            // 수정 모드가 활성화되면 포커스 설정
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isReplyTextFieldFocused = true
                            }
                        }
                    } else {
                        Text(reply.content)
                            .font(.pretendardCaption)
                            .foregroundColor(Color.MainTextColor)
                            .multilineTextAlignment(.leading)
                    }
                }
                Spacer()
            }
            // 답글 실패 시 버튼
            if reply.isTemp && reply.sendFailed {
                HStack(spacing: 8) {
                    Button(action: { onResend(parentCommentId, reply.tempId ?? "") }) {
                        Text("재전송").font(.pretendardCaption).foregroundColor(Color.TomatoRed)
                    }
                    Button(action: { onDelete(parentCommentId, reply.tempId ?? "") }) {
                        Text("삭제").font(.pretendardCaption).foregroundColor(Color.Gray60)
                    }
                }
                .padding(.leading, 47)
            } else if isMine(reply.creator.userId) {
                HStack(spacing: 8) {
                    Button(action: {
                        editText = reply.content
                        isEditing = true
                        editingReplyId = reply.commentId
                        print("대댓글 수정 시작 - editingReplyId: \(reply.commentId)")
                        // 약간의 지연 후 포커스 설정
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isReplyTextFieldFocused = true
                        }
                    }) {
                        Text("수정").font(.pretendardCaption).foregroundColor(Color.Gray60)
                    }
                    Button(action: { onDeleteReal(reply.commentId) }) {
                        Text("삭제").font(.pretendardCaption).foregroundColor(Color.Gray60)
                    }
                }
                .padding(.leading, 47)
            }
        }
        .padding(.leading, 47) // 메인 댓글과 구분하기 위한 들여쓰기
        .padding(.bottom, 8)
    }
}

// MARK: - Alert Modifier
extension PostDetailView {
    @ViewBuilder
    func alertViews() -> some View {
        EmptyView()
            .alert(isPresented: Binding(get: { showResendAlertState.show }, set: { showResendAlertState.show = $0 })) {
                Alert(
                    title: Text("재전송 하시겠습니까?"),
                    primaryButton: .default(Text("재전송")) {
                        if showResendAlertState.isReply {
                            if let parentId = showResendAlertState.parentId, let tempId = showResendAlertState.tempId {
                                container.handle(.resendReply(parentId, tempId))
                            }
                        } else {
                            if let tempId = showResendAlertState.tempId {
                                container.handle(.resendComment(tempId))
                            }
                        }
                        toast = FancyToast(type: .info, title: "재전송", message: "재전송을 시도합니다.", duration: 2)
                    },
                    secondaryButton: .cancel(Text("취소"))
                )
            }
            .alert(isPresented: Binding(get: { showDeleteAlertState.show }, set: { showDeleteAlertState.show = $0 })) {
                Alert(
                    title: Text("삭제 하시겠습니까?"),
                    primaryButton: .destructive(Text("삭제")) {
                        if showDeleteAlertState.isReply {
                            if let parentId = showDeleteAlertState.parentId, let tempId = showDeleteAlertState.tempId {
                                container.handle(.deleteTempReply(parentId, tempId))
                            }
                        } else {
                            if let tempId = showDeleteAlertState.tempId {
                                container.handle(.deleteTempComment(tempId))
                            }
                        }
                        toast = FancyToast(type: .info, title: "삭제", message: "삭제되었습니다.", duration: 2)
                    },
                    secondaryButton: .cancel(Text("취소"))
                )
            }
    }
}
