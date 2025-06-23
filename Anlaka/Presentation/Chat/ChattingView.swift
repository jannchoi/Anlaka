import SwiftUI
import PhotosUI

// MARK: - ChatMessagesView
struct ChatMessagesView: View {
    let messages: [ChatEntity]
    @Binding var scrollProxy: ScrollViewProxy?
    let onScrollToBottom: () -> Void
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { message in
                        ChatMessageCell(
                            message: message,
                            isSending: message.chatId.hasPrefix("temp_")
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onAppear {
                scrollProxy = proxy
                onScrollToBottom()
            }
            .onChange(of: messages.count) { _ in
                onScrollToBottom()
            }
        }
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
    @State private var reconnectAttempts = 0
    @State private var isReconnecting = false
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
                        Text(isReconnecting ? "재연결 시도 중..." : "연결이 끊어졌습니다")
                            .foregroundColor(.TomatoRed)
                        if isReconnecting {
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
                    messages: container.model.sortedMessages,
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
                .padding(.vertical, 8)
                .disabled(container.model.sendingMessageId != nil)
            }
        }
        
        // 네비게이션 및 시트 수정자 적용
        mainContent
            .navigationTitle("채팅")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        path.removeLast()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.MainTextColor)
                            Text("뒤로")
                                .foregroundColor(.MainTextColor)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 4) {
                        Image(systemName: container.model.isConnected ? "wifi" : "wifi.slash")
                            .foregroundColor(container.model.isConnected ? .SteelBlue : .TomatoRed)
                        if isReconnecting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.7)
                        }
                    }
                }
            }
            .onAppear {
                container.handle(.initialLoad)
            }
            .onDisappear {
                container.handle(.disconnectSocket)
            }
            .onChange(of: container.model.isConnected) { isConnected in
                if !isConnected {
                    attemptReconnect()
                } else {
                    isReconnecting = false
                    reconnectAttempts = 0
                }
            }
            .sheet(isPresented: $isShowingImagePicker) {
                ImagePicker(selectedFiles: $selectedFiles)
            }
            .alert("오류", isPresented: .constant(container.model.error != nil)) {
                Button("확인") {
                    container.model.error = nil
                }
                Button("재시도") {
                    container.handle(.initialLoad)
                }
            } message: {
                Text(container.model.error ?? "")
            }
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
    
    private func attemptReconnect() {
        guard !isReconnecting else { return }
        
        isReconnecting = true
        let maxAttempts = 5
        let baseDelay = 1.0 // 초기 지연 시간 (초)
        
        func tryReconnect(attempt: Int) {
            guard attempt < maxAttempts else {
                isReconnecting = false
                container.model.error = "연결을 재설정할 수 없습니다. 앱을 다시 시작해주세요."
                return
            }
            
            let delay = baseDelay * pow(2.0, Double(attempt)) // exponential backoff
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                container.handle(.initialLoad)
            }
        }
        
        tryReconnect(attempt: reconnectAttempts)
        reconnectAttempts += 1
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
            .foregroundColor(isMine ? .white : .black)
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
