import SwiftUI
import PhotosUI

// MARK: - KeyboardResponder
final class KeyboardResponder: ObservableObject {
    private var notificationCenter: NotificationCenter
    @Published private(set) var currentHeight: CGFloat = 0
    
    init(center: NotificationCenter = .default) {
        notificationCenter = center
        notificationCenter.addObserver(self, selector: #selector(keyBoardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyBoardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }
    
    @objc func keyBoardWillShow(notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            currentHeight = keyboardSize.height
        }
    }
    
    @objc func keyBoardWillHide(notification: Notification) {
        currentHeight = 0
    }
}

// MARK: - ChatMessagesView
struct ChatMessagesView: View {
    let messagesGroupedByDate: [(String, [ChatEntity])]
    @Binding var scrollProxy: ScrollViewProxy?
    let onScrollToBottom: () -> Void
    var bottom1: Namespace.ID
    var inputViewHeight: CGFloat
    @ObservedObject var keyboard: KeyboardResponder
    
    var body: some View {
        GeometryReader { geometry in
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messagesGroupedByDate, id: \.0) { date, messages in
                            VStack(spacing: 8) {
                                DateDivider(dateString: date)
                                
                                ForEach(Array(messages.enumerated()), id: \.offset) { index, message in
                                    ChatMessageCell(
                                        message: message,
                                        isSending: message.chatId.hasPrefix("temp_")
                                    )
                                }
                            }
                        }
                        // 키보드가 올라올 때 추가 여백을 제공하여 스크롤 영역 제한
                        Color.clear
                            .frame(height: 1)
                            .id(bottom1)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
                }.background(Color.WarmLinen)
                    .navigationBarHidden(true)
                
                    .onAppear {
                        scrollProxy = proxy
                        onScrollToBottom()
                    }
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
                .font(.pretendardCaption)
                .foregroundColor(.gray)
                .padding(.horizontal, 8)
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
        }
        .padding(.vertical, 8)
    }
}

struct MainContentView: View {
    @ObservedObject var container: ChattingContainer
    @Binding var messageText: String
    @Binding var selectedFiles: [GalleryImage]
    @Binding var isShowingImagePicker: Bool
    @Binding var scrollProxy: ScrollViewProxy?
    @Binding var isShowingProfileDetail: Bool
    @Binding var profileDetailOffset: CGSize
    @Binding var path: NavigationPath
    @Binding var inputViewHeight: CGFloat
    @Binding var didInitialScroll: Bool
    let bottom1: Namespace.ID
    
    @ObservedObject var keyboard: KeyboardResponder
    
    let sendMessage: () -> Void
    let scrollToBottom: () -> Void
    
    var body: some View {
        GeometryReader { mainGeometry in
            ZStack {
                // 키보드 offset을 적용할 컨텐츠 영역 (맨 뒤에 배치)
                VStack(spacing: 0) {
                    if container.model.isLoading {
                        VStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("채팅방을 불러오는 중...")
                    .font(.pretendardBody)
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                            Spacer()
                        }
                    } else {
                        VStack(spacing: 0){
                            // 채팅 메시지 목록
                                                    ChatMessagesView(
                            messagesGroupedByDate: container.model.messagesGroupedByDate,
                            scrollProxy: $scrollProxy,
                            onScrollToBottom: {
                                if !didInitialScroll && !container.model.messages.isEmpty {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                        scrollToBottom()
                                        didInitialScroll = true
                                    }
                                }
                            },
                            bottom1: bottom1,
                            inputViewHeight: inputViewHeight,
                            keyboard: keyboard
                        )
                            .background(Color.warmLinen)
                            
                            // 입력 영역
                            ChatInputView(
                                text: $messageText,
                                selectedFiles: $selectedFiles,
                                onSend: sendMessage,
                                onImagePicker: { isShowingImagePicker = true },
                                isSending: container.model.sendingMessageId != nil
                            )
                            .background(GeometryReader { geo in
                                Color.clear
                                    .onAppear { inputViewHeight = geo.size.height }
                                    .onChange(of: geo.size.height) { newValue in
                                        inputViewHeight = newValue
                                    }
                            })
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .padding(.bottom, keyboard.currentHeight > 0 ? 0 : 16)
                            .disabled(container.model.sendingMessageId != nil)
                            .background(Color.white)
                            
                        }
                        .offset(y: keyboard.currentHeight > 0 ? -(keyboard.currentHeight - inputViewHeight - 2) : 0)
                        .animation(.easeInOut(duration: 0.25), value: keyboard.currentHeight)
                        .ignoresSafeArea(.keyboard)
                    }
                }
                
                // WiFi 상태 표시 (맨 앞에 배치, 키보드 영향 받지 않음)
                VStack {
                    if !container.model.isLoading && !container.model.isConnected {
                        HStack {
                            Image(systemName: "wifi.slash")
                                .foregroundColor(.TomatoRed)
                            Text(container.model.isReconnecting ? "재연결 시도 중..." : "연결이 끊어졌습니다")
                    .font(.pretendardBody)
                                .foregroundColor(.TomatoRed)
                            if container.model.isReconnecting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.7)
                            }
                        }
                        .padding(8)
                        .background(Color.TomatoRed.opacity(0.1))
                        Spacer()
                    }
                }
            }
        }
    }
}

struct ChattingView: View {
    let di: DIContainer
    @AppStorage(TextResource.Global.isLoggedIn.text) private var isLoggedIn: Bool = true
    @StateObject private var container: ChattingContainer
    @StateObject private var keyboard = KeyboardResponder()
    @State private var messageText: String = ""
    @State private var selectedFiles: [GalleryImage] = []
    @State private var isShowingImagePicker = false
    @State private var scrollProxy: ScrollViewProxy? = nil
    @State private var isShowingProfileDetail = false
    @State private var profileDetailOffset: CGSize = .zero
    @Binding var path: NavigationPath
    
    // 스크롤/키보드/입력창 상태 관리
    @State private var inputViewHeight: CGFloat = 0
    @State private var didInitialScroll: Bool = false
    @Namespace var bottom1
    
    
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
        ZStack {
            // MainContentView를 뒤로 보내서 키보드 영향을 받지 않도록 함
            MainContentView(
                container: container,
                messageText: $messageText,
                selectedFiles: $selectedFiles,
                isShowingImagePicker: $isShowingImagePicker,
                scrollProxy: $scrollProxy,
                isShowingProfileDetail: $isShowingProfileDetail,
                profileDetailOffset: $profileDetailOffset,
                path: $path,
                inputViewHeight: $inputViewHeight,
                didInitialScroll: $didInitialScroll,
                bottom1: bottom1,
                keyboard: keyboard,
                sendMessage: sendMessage,
                scrollToBottom: scrollToBottom
            )
            .padding(.top, 25) // CustomNavigationBar 높이만큼 상단 여백 추가
            
            // CustomNavigationBar를 앞으로 보내서 항상 보이도록 함
            VStack {
                CustomNavigationBar(title: container.model.opponentProfile?.nick ?? "채팅") {
                    Button(action: {
                        path.removeLast()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.MainTextColor)
                                                    Text("뒤로")
                            .font(.pretendardBody)
                            .foregroundColor(.MainTextColor)
                        }
                    }
                } rightButton: {
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
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.gray)
                        }
                    }
                }
                Spacer()
            }
        }
        .background(Color.WarmLinen)
        .dismissKeyboardToolbar()
        .onAppear {
            container.handle(.initialLoad)
            didInitialScroll = false
        }
        .onDisappear {
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
                    .font(.pretendardBody)
        }
        .overlay(
            Group {
                if isShowingProfileDetail {
                    ZStack {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isShowingProfileDetail = false
                                }
                            }
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
        
        // 키보드가 올라와 있으면 offset으로 처리, 아니면 scrollTo 사용
        if keyboard.currentHeight > 0 {
            
            // 키보드가 올라와 있을 때는 offset이 이미 적용되어 있으므로 추가 작업 불필요
            return
        } else {
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    self.scrollProxy?.scrollTo(self.bottom1, anchor: .bottom)
                }
            }
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
            .font(.pretendardBody)
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
            .font(.pretendardCaption2)
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
                        .foregroundColor(Color.DeepForest)
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
                    .font(.pretendardCaption)
                    .lineLimit(1)
                Text("파일")
                    .font(.pretendardCaption)
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
