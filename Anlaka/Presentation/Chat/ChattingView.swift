import SwiftUI
import PhotosUI

// MARK: - ChatMessagesView
struct ChatMessagesView: View {
    let messagesGroupedByDate: [(String, [ChatEntity])]
    @Binding var scrollProxy: ScrollViewProxy?
    let onScrollToBottom: () -> Void
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messagesGroupedByDate, id: \.0) { date, messages in
                        VStack(spacing: 12) {
                            DateDivider(dateString: date)
                            
                            ForEach(Array(messages.enumerated()), id: \.offset) { index, message in
                                ChatMessageCell(
                                    message: message,
                                    isSending: message.chatId.hasPrefix("temp_")
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .navigationBarHidden(true)
            .simultaneousGesture(
                DragGesture().onChanged { _ in
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            )
            .onAppear {
                scrollProxy = proxy
                onScrollToBottom()
            }
            .onChange(of: messagesGroupedByDate.flatMap { $0.1 }.count) { _ in
                onScrollToBottom()
            }
        }
    }
}

// MARK: - DateDivider
struct DateDivider: View {
    let dateString: String
    
    var body: some View {
        HStack {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
            
            Text(dateString)
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.horizontal, 8)
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
        }
        .padding(.vertical, 8)
    }
}

struct ChattingView: View {
    let di: DIContainer
    @AppStorage(TextResource.Global.isLoggedIn.text) private var isLoggedIn: Bool = true
    @StateObject private var container: ChattingContainer
    @State private var messageText: String = ""
    @State private var selectedFiles: [GalleryImage] = []
    @State private var isShowingImagePicker = false
    @State private var scrollProxy: ScrollViewProxy? = nil
    @State private var isShowingProfileDetail = false
    @State private var profileDetailOffset: CGSize = .zero
    @Binding var path: NavigationPath
    
    init(opponent_id: String, di: DIContainer, path: Binding<NavigationPath>) {
        self.di = di
        self._path = path
        _container = StateObject(wrappedValue: di.makeChattingContainer(opponent_id: opponent_id))
    }
    
    init(roomId: String, di: DIContainer, path: Binding<NavigationPath>) {
        self.di = di
        self._path = path
        _container = StateObject(wrappedValue: di.makeChattingContainer(roomId: roomId))
    }
    
    var body: some View {
        // 메인 컨텐츠 뷰
        let mainContent = VStack(spacing: 0) {
            if container.model.isLoading {
                // 로딩 인디케이터
                VStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("채팅방을 불러오는 중...")
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                    Spacer()
                }
            } else {
                // 연결 상태 배너
                if !container.model.isConnected {
                    HStack {
                        Image(systemName: "wifi.slash")
                            .foregroundColor(.TomatoRed)
                        Text(container.model.isReconnecting ? "재연결 시도 중..." : "연결이 끊어졌습니다")
                            .foregroundColor(.TomatoRed)
                        if container.model.isReconnecting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.7)
                        }
                    }
                    .padding(8)
                    .background(Color.TomatoRed.opacity(0.1))
                }
                
                // 채팅 메시지 목록
                ChatMessagesView(
                    messagesGroupedByDate: container.model.messagesGroupedByDate,
                    scrollProxy: $scrollProxy,
                    onScrollToBottom: scrollToBottom
                )
                
                // 입력 영역 
                ChatInputView(
                    text: $messageText,
                    selectedFiles: $selectedFiles,
                    onSend: sendMessage,
                    onImagePicker: { isShowingImagePicker = true },
                    isSending: container.model.sendingMessageId != nil
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .disabled(container.model.sendingMessageId != nil)
                .background(Color.white)
            }
        }

        // 네비게이션 및 시트 수정자 적용
        VStack(spacing: 0) {
            // CustomNavigationBar 추가
            CustomNavigationBar(title: container.model.opponentProfile?.nick ?? "채팅") {
                // 뒤로가기 버튼
                Button(action: {
                    print("ChattingView - 뒤로가기 버튼 클릭, 현재 path.count: \(path.count)")
                    path.removeLast()
                    print("ChattingView - path.removeLast() 후 path.count: \(path.count)")
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.MainTextColor)
                        Text("뒤로")
                            .foregroundColor(.MainTextColor)
                    }
                }
            } rightButton: {
                // 상대방 프로필 이미지
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isShowingProfileDetail = true
                    }
                }) {
                    if let profileImage = container.model.opponentProfile?.profileImage {
                        CustomAsyncImage(imagePath: profileImage)
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                    } else {
                        // 프로필 이미지가 없는 경우 기본 이미지
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.gray)
                    }
                }
            }
            
            mainContent
        }
        .onAppear {
            container.handle(.initialLoad)
        }
        .onDisappear {
            print("ChattingView - onDisappear 호출됨")
            container.handle(.disconnectSocket)
        }
        .sheet(isPresented: $isShowingImagePicker) {
            ImagePicker(selectedFiles: $selectedFiles)
        }
        .alert("오류", isPresented: .constant(container.model.error != nil)) {
            Button("확인") {
                container.handle(.setError(nil))
            }
            Button("재시도") {
                container.handle(.initialLoad)
            }
        } message: {
            Text(container.model.error ?? "")
        }
        .overlay(
            // ProfileDetailView Overlay
            Group {
                if isShowingProfileDetail {
                    ZStack {
                        // 배경 어둡게 처리
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isShowingProfileDetail = false
                                }
                            }
                        
                        // ProfileDetailView
                        if let opponentProfile = container.model.opponentProfile {
                            ProfileDetailView(
                                profileImage: opponentProfile.profileImage,
                                nick: opponentProfile.nick,
                                introduction: opponentProfile.introduction,
                                isPresented: $isShowingProfileDetail
                            )
                            .offset(profileDetailOffset)
                            .scaleEffect(isShowingProfileDetail ? 1.0 : 0.1)
                            .opacity(isShowingProfileDetail ? 1.0 : 0.0)
                            .animation(.easeInOut(duration: 0.3), value: isShowingProfileDetail)
                        }
                    }
                    .transition(.opacity)
                }
            }
        )
    }

    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !selectedFiles.isEmpty else { return }
        container.handle(.sendMessage(text: messageText, files: selectedFiles))
        messageText = ""
        selectedFiles = []
    }
    
    private func scrollToBottom() {
        withAnimation {
            scrollProxy?.scrollTo(container.model.messages.last?.chatId, anchor: .bottom)
        }
    }
}

// MARK: - ChatMessageCell
struct ChatMessageCell: View {
    let message: ChatEntity
    let isSending: Bool
    
    var body: some View {
        HStack {
            if message.isMine {
                Spacer()
            }
            
            MessageContentView(message: message, isSending: isSending)
            
            if !message.isMine {
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - MessageContentView
private struct MessageContentView: View {
    let message: ChatEntity
    let isSending: Bool
    
    var body: some View {
        VStack(alignment: message.isMine ? .trailing : .leading, spacing: 8) {
            HStack(spacing: 8) {
                if message.isMine && isSending {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.7)
                }
                
                if !message.content.isEmpty {
                    MessageText(content: message.content, isMine: message.isMine)
                }
            }
            
            if !message.files.isEmpty {
                FilePreviewView(files: message.files)
            }
            
            MessageTimeView(createdAt: message.createdAt)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - MessageText
private struct MessageText: View {
    let content: String
    let isMine: Bool
    
    var body: some View {
        Text(content)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isMine ? Color.OliveMist : Color.gray.opacity(0.2))
            .foregroundColor(isMine ? .white : Color.MainTextColor)
            .cornerRadius(12)
    }
}

// MARK: - MessageTimeView
private struct MessageTimeView: View {
    let createdAt: String
    
    var body: some View {
        Text(PresentationMapper.formatISO8601ToTimeString(createdAt))
            .font(.caption2)
            .foregroundColor(.gray)
    }
}

// MARK: - ChatInputView
struct ChatInputView: View {
    @Binding var text: String
    @Binding var selectedFiles: [GalleryImage]
    let onSend: () -> Void
    let onImagePicker: () -> Void
    let isSending: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // 선택된 파일 미리보기
            if !selectedFiles.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(selectedFiles.indices, id: \.self) { index in
                            FileThumbnailView(file: selectedFiles[index]) {
                                selectedFiles.remove(at: index)
                            }
                        }
                    }
                }
                .frame(height: 80)
            }
            
            // 입력 영역
            HStack(spacing: 8) {
                Button(action: onImagePicker) {
                    Image(systemName: "photo")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                }
                .disabled(isSending)
                
                TextField("메시지를 입력하세요", text: $text, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...3)
                    .disabled(isSending)
                
                Button(action: onSend) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(isValidInput ? .OliveMist : .Deselected)
                }
                .disabled(!isValidInput || isSending)
            }
        }
    }
    
    private var isValidInput: Bool {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedText.count >= 1
    }
}

// MARK: - FilePreviewView
struct FilePreviewView: View {
    let files: [String]
    
    var body: some View {
        if files.count == 1 {
            SingleFilePreview(fileURL: files[0])
        } else {
            FileGridPreview(files: files)
        }
    }
}

struct SingleFilePreview: View {
    let fileURL: String
    
    var body: some View {
        if isImageFile {
            CustomAsyncImage(imagePath: fileURL)
                .frame(width: 200, height: 200)
                .cornerRadius(8)
        } else {
            // 파일 확장자에 따른 아이콘 표시
            Image(systemName: fileIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.gray)
                .padding()
                .frame(width: 200, height: 200)
                .cornerRadius(8)
        }
    }
    
    private var fileExtension: String {
        URL(string: fileURL)?.pathExtension.lowercased() ?? ""
    }
    
    private var isImageFile: Bool {
        ["jpg", "jpeg", "png", "gif"].contains(fileExtension)
    }
    
    private var fileIcon: String {
        switch fileExtension {
        case "jpg", "jpeg", "png", "gif":
            return "photo"
        case "pdf":
            return "doc.text"
        default:
            return "doc"
        }
    }
}

struct FileGridPreview: View {
    let files: [String]
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 8) {
            ForEach(files.indices, id: \.self) { index in
                SingleFilePreview(fileURL: files[index])
            }
        }
    }
}

struct FileInfoView: View {
    let file: FileEntity
    
    var body: some View {
        HStack {
            Image(systemName: "doc.fill")
                .foregroundColor(.gray)
            VStack(alignment: .leading) {
                Text(file.path.components(separatedBy: "/").last ?? "")
                    .lineLimit(1)
                Text("파일")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func formatFileSize(_ url: URL) -> String {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? Int64 {
                let formatter = ByteCountFormatter()
                formatter.allowedUnits = [.useKB, .useMB]
                formatter.countStyle = .file
                return formatter.string(fromByteCount: fileSize)
            }
        } catch {
            print("Error getting file size: \(error)")
        }
        return "Unknown size"
    }
}

struct FileThumbnailView: View {
    let file: GalleryImage
    let onRemove: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: file.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 60)
                .cornerRadius(8)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
                    .background(Color.white)
                    .clipShape(Circle())
            }
            .offset(x: 6, y: -6)
        }
    }
}

// MARK: - ImagePicker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedFiles: [GalleryImage]
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 5
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                        if let image = image as? UIImage {
                            DispatchQueue.main.async {
                                result.itemProvider.loadFileRepresentation(forTypeIdentifier: "public.image") { url, error in
                                    if let url = url {
                                        // GalleryImage 생성
                                        let galleryImage = GalleryImage(image: image, fileName: url.lastPathComponent)
                                        DispatchQueue.main.async {
                                            self?.parent.selectedFiles.append(galleryImage)
                                        }
                                    } else {
                                        // URL이 없는 경우 임시 GalleryImage 생성
                                        let galleryImage = GalleryImage(image: image, fileName: "image.jpg")
                                        DispatchQueue.main.async {
                                            self?.parent.selectedFiles.append(galleryImage)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
