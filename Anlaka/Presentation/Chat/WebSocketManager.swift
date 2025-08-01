import Foundation
import Network
import SocketIO

class WebSocketManager {
    private(set) var socket: SocketIOClient?
    private let roomId: String
    private var networkMonitor: NWPathMonitor?
    private var isConnected = false
    private var isConnecting = false
    private var reconnectTimer: Timer?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private let connectionQueue = DispatchQueue(label: "com.anlaka.websocket.connection")
    private var manager: SocketManager?
    
    // 백그라운드/포그라운드 상태 추적
    private var isAppInBackground = false
    private var shouldReconnectOnForeground = false
    
    var onMessage: ((ChatMessageEntity) -> Void)?
    var onConnectionStatusChanged: ((Bool) -> Void)?
    
    init(roomId: String) {
        self.roomId = roomId
        setupNetworkMonitoring()
        setupAppLifecycleObserver()
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor = NWPathMonitor()
        networkMonitor?.pathUpdateHandler = { [weak self] path in
            self?.connectionQueue.async {
                if path.status == .satisfied {
                    if !(self?.isConnected ?? false) && !(self?.isConnecting ?? false) {
                        self?.attemptReconnect()
                    }
                } else {
                    self?.handleDisconnection()
                }
            }
        }
        networkMonitor?.start(queue: DispatchQueue.global())
    }
    
    func connect() {
        connectionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // 앱이 백그라운드 상태면 연결하지 않고 플래그만 설정
            if self.isAppInBackground {
                print("🔵 앱이 백그라운드 상태 - 연결 지연")
                self.shouldReconnectOnForeground = true
                return
            }
            
            // 이미 연결되어 있거나 연결 중이면 중복 연결 방지
            guard !self.isConnected && !self.isConnecting else {
                print("이미 연결되어 있거나 연결 중입니다.")
                return
            }
            
            self.isConnecting = true
            
            // Socket.IO 설정
            guard let url = URL(string: BaseURL.baseURL) else {
                self.isConnecting = false
                return
            }
            
            let config: SocketIOClientConfiguration = [
                .log(true),
                .compress,
                .forceWebsockets(true),
                .reconnects(true),
                .reconnectAttempts(5),
                .reconnectWait(1),
                .extraHeaders([
                    "SeSACKey": AppConfig.apiKey,
                    "Authorization": KeychainManager.shared.getString(forKey: .accessToken) ?? ""
                ])
            ]
            
            self.manager = SocketManager(socketURL: url, config: config)
            
            // namespace 설정
            let namespace = "/chats-\(self.roomId)"
            print("🔧 [WebSocket] 네임스페이스 설정: \(namespace)")
            self.socket = self.manager?.socket(forNamespace: namespace)
            
            // 연결 이벤트 핸들러
            self.socket?.on(clientEvent: .connect) { [weak self] data, ack in
                print("SOCKET IS CONNECTED", data, ack)
                self?.connectionQueue.async {
                    self?.isConnecting = false
                    self?.isConnected = true
                    self?.onConnectionStatusChanged?(true)
                    self?.reconnectAttempts = 0
                }
            }
            
            // 연결 해제 이벤트 핸들러
            self.socket?.on(clientEvent: .disconnect) { [weak self] data, ack in
                print("SOCKET IS DISCONNECTED", data, ack)
                self?.handleDisconnection()
            }
            
            // 재연결 시도 이벤트 핸들러
            self.socket?.on(clientEvent: .reconnect) { [weak self] data, ack in
                print("SOCKET RECONNECTING", data, ack)
                self?.isConnecting = true
            }
            
            // 재연결 시도 이벤트 핸들러
            self.socket?.on(clientEvent: .reconnectAttempt) { [weak self] data, ack in
                print("SOCKET RECONNECT ATTEMPT", data, ack)
                self?.isConnecting = true
            }
            
            // 연결 에러 이벤트 핸들러
            self.socket?.on(clientEvent: .error) { [weak self] data, ack in
                print("SOCKET ERROR", data, ack)
                // 재연결 시도 중 에러가 발생한 경우
                if self?.isConnecting == true {
                    self?.handleDisconnection()
                }
            }
            
            // 채팅 메시지 수신 이벤트 핸들러
            self.socket?.on("chat") { [weak self] dataArray, ack in
                print("CHAT RECEIVED", dataArray, ack)
                if let data = dataArray.first as? [String: Any] {
                    print(" 수신된 메시지 데이터:", data)
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: data)
                        let message = try JSONDecoder().decode(ChatMessageDTO.self, from: jsonData)
                        guard let entity = message.toEntity() else {
                            print("⚠️ 메시지 변환 실패: 필수 필드가 nil입니다. chatID: \(message.chatID ?? "nil"), roomID: \(message.roomID ?? "nil"), sender: \(message.sender?.userID ?? "nil")")
                            return // 에러를 throw하지 않고 조용히 무시
                        }
                        print(" 메시지 변환 성공:", entity)
                        DispatchQueue.main.async {
                            self?.onMessage?(entity)
                        }
                    } catch {
                        print("❌ 메시지 변환 실패:", error)
                        // 에러를 throw하지 않고 조용히 무시하여 WebSocket 연결 유지
                    }
                }
            }
            
            // 연결 시도
            self.socket?.connect()
        }
    }
    
    private func cleanupExistingConnection() {
        socket?.disconnect()
        socket = nil
        manager = nil
        isConnected = false
        isConnecting = false
    }
    
    func disconnect() {
        connectionQueue.async { [weak self] in
            self?.cleanupExistingConnection()
            self?.onConnectionStatusChanged?(false)
            self?.shouldReconnectOnForeground = false
        }
    }
    
    private func handleDisconnection() {
        connectionQueue.async { [weak self] in
            self?.cleanupExistingConnection()
            self?.onConnectionStatusChanged?(false)
            self?.attemptReconnect()
        }
    }
    
    private func attemptReconnect() {
        connectionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // 이미 연결되어 있거나 연결 중이면 재연결 시도하지 않음
            guard !self.isConnected && !self.isConnecting else { return }
            
            // 이미 재연결 시도 중이면 중복 실행 방지
            if self.reconnectTimer != nil { return }
            
            // 최대 재시도 횟수 초과 시 중단
            guard self.reconnectAttempts < self.maxReconnectAttempts else {
                print("최대 재연결 시도 횟수 초과")
                return
            }
            
            // exponential backoff 적용
            let delay = pow(2.0, Double(self.reconnectAttempts)) * 1.0
            self.reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                self?.connectionQueue.async {
                    self?.reconnectTimer = nil
                    self?.connect()
                    self?.reconnectAttempts += 1
                }
            }
        }
    }
    
    func emit(_ event: String, with items: [Any], completion: @escaping () -> Void) {
        connectionQueue.async { [weak self] in
            print(" 메시지 전송 시작:", event, items)
            
            // 일반 emit 사용 (ack 없이)
            self?.socket?.emit(event, items)
            
            // 메시지 전송 후 HTTP 요청을 통해 저장
            completion()
        }
    }
    
    func emit(_ event: String, _ items: Any...) {
        connectionQueue.async { [weak self] in
            self?.socket?.emit(event, items)
        }
    }
    
    func emit(_ event: String, with items: [Any]) {
        connectionQueue.async { [weak self] in
            self?.socket?.emit(event, items)
        }
    }
    
    // MARK: - 앱 생명주기 이벤트 처리
    private func setupAppLifecycleObserver() {
        // SceneDelegate에서 전송하는 채팅 소켓 제어 알림
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(chatSocketShouldDisconnect),
            name: .chatSocketShouldDisconnect,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(chatSocketShouldReconnect),
            name: .chatSocketShouldReconnect,
            object: nil
        )
    }
    
    @objc private func chatSocketShouldDisconnect() {
        print("🔵 WebSocketManager: SceneDelegate에서 소켓 해제 요청")
        isAppInBackground = true
        
        // 백그라운드 진입 시 소켓 해제
        connectionQueue.async { [weak self] in
            self?.cleanupExistingConnection()
            self?.onConnectionStatusChanged?(false)
        }
    }
    
    @objc private func chatSocketShouldReconnect() {
        print("🟢 WebSocketManager: SceneDelegate에서 소켓 재연결 요청")
        isAppInBackground = false
        
        // 포그라운드 복귀 시 재연결 시도
        if shouldReconnectOnForeground {
            print("🟢 WebSocketManager: 포그라운드 복귀 시 재연결 시도")
            shouldReconnectOnForeground = false
            attemptReconnect()
        }
    }
    
    deinit {
        networkMonitor?.cancel()
        reconnectTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
        disconnect()
    }
} 

