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
    @Binding var showNewMessageButton: Bool
    @Binding var isAtBottom: Bool
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                ScrollViewReader { proxy in
                    ScrollView(.vertical) {
                        LazyVStack(spacing: 12) {
                            ForEach(messagesGroupedByDate, id: \.0) { date, messages in
                                VStack(spacing: 8) {
                                    DateDivider(dateString: date)
                                        .rotationEffect(.degrees(180))
                                        .scaleEffect(x: -1, y: 1, anchor: .center)
                                    ForEach(Array(messages.enumerated()), id: \.offset) { index, message in
                                        ChatMessageCell(
                                            message: message,
                                            isSending: message.chatId.hasPrefix("temp_")
                                        )
                                        .rotationEffect(.degrees(180))
                                        .scaleEffect(x: -1, y: 1, anchor: .center)
                                    }
                                }
                            }
                            Color.clear
                                .frame(height: 1)
                                .id(bottom1)
                        }
                        .padding(.horizontal, 16)
                        //.padding(.top, 140)
                        //.padding(.bottom, 100)
                        .rotationEffect(.degrees(180))
                        .scaleEffect(x: -1, y: 1, anchor: .center)
                    }
                    .rotationEffect(.degrees(180))
                    .scaleEffect(x: -1, y: 1, anchor: .center)
                    .background(Color.WarmLinen)
                    .onTapGesture {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .onAppear {
                        scrollProxy = proxy
                        onScrollToBottom()
                    }
                    .onChange(of: messagesGroupedByDate.count) { _ in
                        checkScrollPosition(proxy: proxy)
                        if isAtBottom {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                onScrollToBottom()
                            }
                        }
                    }
                    .onChange(of: messagesGroupedByDate.flatMap { $0.1 }.count) { _ in
                        checkScrollPosition(proxy: proxy)
                        if isAtBottom {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                onScrollToBottom()
                            }
                        }
                    }
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { _ in checkScrollPosition(proxy: proxy) }
                            .onEnded { _ in checkScrollPosition(proxy: proxy) }
                    )
                }
            }
            // emptyView 추가
            Color.clear
                .frame(height: keyboard.currentHeight > 0 ? keyboard.currentHeight + inputViewHeight : inputViewHeight)
        }
        
    }
    private func checkScrollPosition(proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let totalMessages = messagesGroupedByDate.flatMap { $0.1 }.count
            let hasMessages = totalMessages > 0
            let isNearBottom = hasMessages // 임시로 메시지가 있으면 하단에 있다고 가정
            withAnimation(.easeInOut(duration: 0.3)) {
                isAtBottom = isNearBottom
                showNewMessageButton = hasMessages && !isNearBottom
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
        .rotationEffect(.degrees(180))
        .scaleEffect(x: -1, y: 1, anchor: .center)
    }
}

// CustomNavigationBar 높이 측정용 PreferenceKey
struct CustomNavigationBarHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct MainContentView: View {
    @ObservedObject var container: ChattingContainer
    @Binding var messageText: String
    @Binding var selectedFiles: [SelectedFile]
    @Binding var isShowingImagePicker: Bool
    @Binding var scrollProxy: ScrollViewProxy?
    @Binding var isShowingProfileDetail: Bool
    @Binding var profileDetailOffset: CGSize
    @Binding var path: NavigationPath
    @Binding var inputViewHeight: CGFloat
    @Binding var didInitialScroll: Bool
    @Binding var isShowingDocumentPicker: Bool
    let bottom1: Namespace.ID
    @ObservedObject var keyboard: KeyboardResponder
    let sendMessage: () -> Void
    let scrollToBottom: () -> Void
    let navigationBarHeight: CGFloat // 추가
    @State private var showNewMessageButton: Bool = false
    @State private var isAtBottom: Bool = true
    
    var body: some View {
        GeometryReader { mainGeometry in
            ZStack(alignment: .bottom) {
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
                            keyboard: keyboard,
                            showNewMessageButton: $showNewMessageButton,
                            isAtBottom: $isAtBottom
                        )
                    }
                }
                ChatInputView(
                    text: $messageText,
                    selectedFiles: $selectedFiles,
                    invalidFileIndices: container.model.invalidFileIndices,
                    onSend: sendMessage,
                    onImagePicker: { isShowingImagePicker = true },
                    onDocumentPicker: { isShowingDocumentPicker = true },
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
                .padding(.bottom, keyboard.currentHeight)
                .background(Color.white)
                .disabled(container.model.sendingMessageId != nil)
            }
            .ignoresSafeArea(.keyboard)
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
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    if showNewMessageButton {
                        newMessageButton
                            .padding(.trailing, 12)
                            .padding(.bottom, keyboard.currentHeight > 0 ? inputViewHeight + 48 : inputViewHeight + 36)
                            .animation(.easeInOut(duration: 0.1), value: keyboard.currentHeight)
                    }
                }
            }
        }
    }
    private var newMessageButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.25)) {
                scrollToBottom()
            }
        }) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 40, height: 40)
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 2)
                Image(systemName: "arrow.down.message")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.OliveMist)
                    .frame(width: 30, height: 30)
            }
        }
        .transition(.scale.combined(with: .opacity))
    }
}

struct ChattingView: View {
    let di: DIContainer
    @AppStorage(TextResource.Global.isLoggedIn.text) private var isLoggedIn: Bool = true
    @StateObject private var container: ChattingContainer
    @StateObject private var keyboard = KeyboardResponder()
    @State private var messageText: String = ""
    @State private var selectedFiles: [SelectedFile] = []
    @State private var isShowingImagePicker = false
    @State private var isShowingDocumentPicker = false
    @State private var scrollProxy: ScrollViewProxy? = nil
    @State private var isShowingProfileDetail = false
    @State private var profileDetailOffset: CGSize = .zero
    @Binding var path: NavigationPath
    @State private var inputViewHeight: CGFloat = 0
    @State private var didInitialScroll: Bool = false
    @State private var navigationBarHeight: CGFloat = 0 // 추가
    @Namespace var bottom1
    private var displayNick: String {
        guard let nick = container.model.opponentProfile?.nick else { return "채팅" }
        return nick.count > 17 ? String(nick.prefix(20)) + "..." : nick
    }
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
        VStack(spacing: 0) {
            CustomNavigationBar(title: displayNick) {
                Button(action: {
                    if !path.isEmpty {
                        path.removeLast()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image("chevron")
                            .font(.headline)
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
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(key: CustomNavigationBarHeightKey.self, value: geo.size.height)
                }
            )
            .onPreferenceChange(CustomNavigationBarHeightKey.self) { height in
                self.navigationBarHeight = height
            }
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
                isShowingDocumentPicker: $isShowingDocumentPicker,
                bottom1: bottom1,
                keyboard: keyboard,
                sendMessage: sendMessage,
                scrollToBottom: scrollToBottom,
                navigationBarHeight: navigationBarHeight // 추가
            )
        }
        .background(Color.white)
        .onAppear {
            container.handle(.initialLoad)
            didInitialScroll = false
            CurrentScreenTracker.shared.setCurrentScreen(.chat, chatRoomId: container.model.roomId)
            
            // 채팅방 진입 시 알림 카운트 초기화
            ChatNotificationCountManager.shared.resetCount(for: container.model.roomId)
        }
        .onDisappear {
            container.handle(.disconnectSocket)
        }
        .sheet(isPresented: $isShowingImagePicker) {
            FilePicker(
                selectedFiles: $selectedFiles,
                pickerType: .chat
            )
            .onChange(of: selectedFiles) { files in
                container.handle(.validateFiles(files))
            }
        }
        .sheet(isPresented: $isShowingDocumentPicker) {
            DocumentPicker(
                selectedFiles: $selectedFiles,
                pickerType: .chat
            )
            .onChange(of: selectedFiles) { files in
                container.handle(.validateFiles(files))
            }
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
        .toastView(toast: $container.model.toast)
    }
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !selectedFiles.isEmpty else { return }
        container.handle(.sendMessage(text: messageText, files: selectedFiles))
        messageText = ""
        selectedFiles = []
    }
private func scrollToBottom() {
    guard let scrollProxy = self.scrollProxy else {
        return
    }
    
    if keyboard.currentHeight > 0 {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.25)) {
                scrollProxy.scrollTo(self.bottom1, anchor: .bottom)
            }
        }
    } else {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.25)) {
                scrollProxy.scrollTo(self.bottom1, anchor: .bottom)
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
        .rotationEffect(.degrees(180))
        .scaleEffect(x: -1, y: 1, anchor: .center)
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
    @Binding var selectedFiles: [SelectedFile]
    let invalidFileIndices: Set<Int>
    let onSend: () -> Void
    let onImagePicker: () -> Void
    let onDocumentPicker: () -> Void
    let isSending: Bool
    let showFileUpload: Bool // 파일 업로드 기능 표시 여부
    
    init(
        text: Binding<String>,
        selectedFiles: Binding<[SelectedFile]>,
        invalidFileIndices: Set<Int>,
        onSend: @escaping () -> Void,
        onImagePicker: @escaping () -> Void,
        onDocumentPicker: @escaping () -> Void,
        isSending: Bool,
        showFileUpload: Bool = true // 기본값은 true (채팅에서 사용)
    ) {
        self._text = text
        self._selectedFiles = selectedFiles
        self.invalidFileIndices = invalidFileIndices
        self.onSend = onSend
        self.onImagePicker = onImagePicker
        self.onDocumentPicker = onDocumentPicker
        self.isSending = isSending
        self.showFileUpload = showFileUpload
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // 파일 선택 안내 (파일 업로드가 활성화된 경우에만 표시)
            if showFileUpload {
                HStack {
                    Text(selectedFiles.isEmpty ? "파일을 선택하세요" : "\(selectedFiles.count)개 선택됨")
                        .font(.pretendardCaption)
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding(.horizontal, 4)
                //.padding(.top, 8) // X 버튼이 보이도록 상단 패딩 추가
                
                // 선택된 파일 미리보기
                if !selectedFiles.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(selectedFiles.indices, id: \.self) { idx in
                                SelectedFileThumbnailView(file: selectedFiles[idx], isInvalid: invalidFileIndices.contains(idx), invalidReason: nil) {
                                    selectedFiles.remove(at: idx)
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.top, 4)
                    }
                    .frame(height: 90)
                }
            }
            
            // 입력 영역
            HStack(spacing: 8) {
                // 갤러리 버튼 (파일 업로드가 활성화된 경우에만 표시)
                if showFileUpload {
                    Button(action: onImagePicker) {
                        Image(systemName: "photo")
                            .font(.system(size: 20))
                            .foregroundColor(Color.DeepForest)
                    }
                    .disabled(isSending)
                    
                    // 문서 선택 버튼 (파일 업로드가 활성화된 경우에만 표시)
                    Button(action: onDocumentPicker) {
                        Image(systemName: "doc")
                            .font(.system(size: 20))
                            .foregroundColor(Color.DeepForest)
                    }
                    .disabled(isSending)
                }
                
                TextField(showFileUpload ? "메시지를 입력하세요" : "댓글을 입력하세요", text: $text, axis: .vertical)
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
        let hasValidText = trimmedText.count >= 1
        let hasValidFiles = selectedFiles.isEmpty || invalidFileIndices.isEmpty
        return hasValidText || hasValidFiles
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
            CustomAsyncImage.listCell(imagePath: fileURL)
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

struct SelectedFileThumbnailView: View {
    let file: SelectedFile
    let isInvalid: Bool
    let invalidReason: String?
    let onRemove: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // 파일 타입에 따른 썸네일 표시
            Group {
                switch file.fileType {
                case .image:
                    if let image = file.image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                    } else {
                        Color.gray.opacity(0.3)
                            .frame(width: 60, height: 60)
                    }
                case .video:
                    VStack(spacing: 4) {
                        Image(systemName: "video.slash")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                        Text(file.fileExtension.uppercased())
                            .font(.pretendardCaption2)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.1))
                case .pdf:
                    VStack(spacing: 4) {
                        Image(systemName: "doc.text.slash")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                        Text("PDF")
                            .font(.pretendardCaption2)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.1))
                }
            }
            .frame(width: 60, height: 60)
            .cornerRadius(8)
            .clipped()
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isInvalid ? Color.red : Color.clear, lineWidth: 2)
            )
            
            // 파일 크기 표시
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text(formatFileSize(file.sizeMB))
                        .font(.pretendardCaption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(4)
                }
            }
            .frame(width: 60, height: 60)
            
            // 유효하지 않은 파일 원인 표시 (선택사항)
            if isInvalid, let reason = invalidReason {
                VStack {
                    HStack {
                        Spacer()
                        Text(reason)
                            .font(.pretendardCaption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(4)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                }
                .frame(width: 60, height: 60)
            }
            
            // 삭제 버튼
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(isInvalid ? .red : .gray)
                    .background(Color.white)
                    .clipShape(Circle())
            }
            .offset(x: 6, y: -6)
        }
    }
    
    private func formatFileSize(_ sizeMB: Double) -> String {
        if sizeMB >= 1.0 {
            return String(format: "%.1fMB", sizeMB)
        } else {
            return String(format: "%.0fKB", sizeMB * 1024)
        }
    }
}




