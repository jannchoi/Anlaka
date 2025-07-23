import Foundation

// MARK: - 딥링크 URL 스키마 정의
enum DeepLinkScheme {
    static let scheme = "anlaka"
    static let host = "navigate"
    
    // URL 구성 요소
    enum QueryKey {
        static let type = "type"
        static let id = "id"
        static let source = "source"
    }
    
    // 딥링크 타입
    enum DeepLinkType: String, CaseIterable {
        case chat = "chat"
        case estate = "estate"
        case post = "post"
        case profile = "profile"
        case settings = "settings"
    }
    
    // 딥링크 소스
    enum DeepLinkSource: String, CaseIterable {
        case pushNotification = "push"
        case externalLink = "external"
        case inAppAction = "inapp"
    }
}

// MARK: - 딥링크 데이터 모델
struct DeepLinkData {
    let type: DeepLinkScheme.DeepLinkType
    let id: String
    let source: DeepLinkScheme.DeepLinkSource
    let timestamp: Date
    
    init(type: DeepLinkScheme.DeepLinkType, id: String, source: DeepLinkScheme.DeepLinkSource = .pushNotification) {
        self.type = type
        self.id = id
        self.source = source
        self.timestamp = Date()
    }
}

// MARK: - 딥링크 URL 생성 및 파싱
extension DeepLinkScheme {
    /// 딥링크 URL 생성
    static func createURL(type: DeepLinkType, id: String, source: DeepLinkSource = .pushNotification) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.queryItems = [
            URLQueryItem(name: QueryKey.type, value: type.rawValue),
            URLQueryItem(name: QueryKey.id, value: id),
            URLQueryItem(name: QueryKey.source, value: source.rawValue)
        ]
        return components.url
    }
    
    /// URL에서 딥링크 데이터 파싱
    static func parseURL(_ url: URL) -> DeepLinkData? {
        guard url.scheme == scheme,
              url.host == host,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems else {
            print("❌ 딥링크 URL 파싱 실패: 잘못된 URL 형식")
            return nil
        }
        
        // 필수 파라미터 추출
        guard let typeString = queryItems.first(where: { $0.name == QueryKey.type })?.value,
              let type = DeepLinkType(rawValue: typeString),
              let id = queryItems.first(where: { $0.name == QueryKey.id })?.value,
              !id.isEmpty else {
            print("❌ 딥링크 URL 파싱 실패: 필수 파라미터 누락")
            return nil
        }
        
        // 소스 파라미터 추출 (선택적)
        let sourceString = queryItems.first(where: { $0.name == QueryKey.source })?.value
        let source = DeepLinkSource(rawValue: sourceString ?? "") ?? .pushNotification
        
        return DeepLinkData(type: type, id: id, source: source)
    }
}

// MARK: - 딥링크 처리 결과
enum DeepLinkResult {
    case success(DeepLinkData)
    case invalidURL
    case unsupportedType
    case invalidID
    case processingError(String)
}

// MARK: - 딥링크 처리 상태
@MainActor
class DeepLinkProcessor: ObservableObject {
    static let shared = DeepLinkProcessor()
    
    @Published var isProcessing = false
    @Published var lastProcessedLink: DeepLinkData?
    
    private var processingQueue: [DeepLinkData] = []
    private var isProcessingQueue = false
    
    private init() {}
    
    /// 딥링크 처리 (중복 방지 및 큐잉)
    func processDeepLink(_ url: URL) {
        guard let deepLinkData = DeepLinkScheme.parseURL(url) else {
            print("❌ 딥링크 URL 파싱 실패: \(url)")
            return
        }
        
        // 중복 처리 방지 (같은 타입과 ID의 최근 요청 무시)
        if let lastLink = lastProcessedLink,
           lastLink.type == deepLinkData.type,
           lastLink.id == deepLinkData.id,
           Date().timeIntervalSince(lastLink.timestamp) < 1.0 {
            return
        }
        
        // 채팅방 딥링크의 경우 현재 채팅방과 동일한지 확인
        if deepLinkData.type == .chat {
            let currentChatRoomId = CurrentScreenTracker.shared.currentChatRoomId
            
            // 현재 채팅방과 동일하고, 푸시 알림이 아닌 경우에만 스킵
            if currentChatRoomId == deepLinkData.id && deepLinkData.source != .pushNotification {
                return
            }
            
            // 현재 채팅방과 동일하고 푸시 알림인 경우 - 현재 채팅방에 있을 때만 스킵
            if currentChatRoomId == deepLinkData.id && deepLinkData.source == .pushNotification {
                let isInChatRoom = CurrentScreenTracker.shared.isInSpecificChatRoom(roomId: deepLinkData.id)
                if isInChatRoom {
                    return
                }
            }
        }
        
        // 큐에 추가
        processingQueue.append(deepLinkData)
        
        // 큐 처리 시작
        if !isProcessingQueue {
            processQueue()
        }
    }
    
    /// 큐 처리
    private func processQueue() {
        guard !processingQueue.isEmpty && !isProcessingQueue else { 
            return 
        }
        
        isProcessingQueue = true
        isProcessing = true
        
        while !processingQueue.isEmpty {
            let deepLinkData = processingQueue.removeFirst()
            lastProcessedLink = deepLinkData
            
            // 딥링크 타입별 처리
            switch deepLinkData.type {
            case .chat:
                handleChatDeepLink(deepLinkData)
            case .estate:
                handleEstateDeepLink(deepLinkData)
            case .post:
                handlePostDeepLink(deepLinkData)
            case .profile:
                handleProfileDeepLink(deepLinkData)
            case .settings:
                handleSettingsDeepLink(deepLinkData)
            }
        }
        
        isProcessing = false
        isProcessingQueue = false
    }
    
    /// 채팅 딥링크 처리
    private func handleChatDeepLink(_ data: DeepLinkData) {
        // RoutingStateManager를 통해 직접 처리
        let routingManager = RoutingStateManager.shared
        routingManager.navigateToChatRoom(data.id)
    }
    
    /// 부동산 딥링크 처리
    private func handleEstateDeepLink(_ data: DeepLinkData) {
        print("📱 부동산 딥링크 처리: \(data.id)")
        
        // RoutingStateManager를 통해 처리
        let routingManager = RoutingStateManager.shared
        routingManager.pendingNavigation = .estateDetail(estateId: data.id)
    }
    
    /// 게시글 딥링크 처리
    private func handlePostDeepLink(_ data: DeepLinkData) {
        print("📱 게시글 딥링크 처리: \(data.id)")
        
        // RoutingStateManager를 통해 처리
        let routingManager = RoutingStateManager.shared
        routingManager.pendingNavigation = .postDetail(postId: data.id)
    }
    
    /// 프로필 딥링크 처리
    private func handleProfileDeepLink(_ data: DeepLinkData) {
        print("📱 프로필 딥링크 처리: \(data.id)")
        
        // RoutingStateManager를 통해 처리
        let routingManager = RoutingStateManager.shared
        routingManager.pendingNavigation = .profile
    }
    
    /// 설정 딥링크 처리
    private func handleSettingsDeepLink(_ data: DeepLinkData) {
        print("📱 설정 딥링크 처리: \(data.id)")
        
        // RoutingStateManager를 통해 처리
        let routingManager = RoutingStateManager.shared
        routingManager.pendingNavigation = .settings
    }
    
    /// 큐 초기화
    func clearQueue() {
        processingQueue.removeAll()
        isProcessing = false
        isProcessingQueue = false
        print("📱 딥링크 처리 큐 초기화")
    }
    
    /// 테스트용 딥링크 생성
    static func createTestDeepLink(type: DeepLinkScheme.DeepLinkType, id: String) -> URL? {
        return DeepLinkScheme.createURL(type: type, id: id, source: .inAppAction)
    }
    
    /// 테스트용 채팅방 딥링크 처리
    func processTestChatDeepLink(roomId: String) {
        if let testURL = DeepLinkProcessor.createTestDeepLink(type: .chat, id: roomId) {
            print("📱 테스트 채팅 딥링크 생성: \(testURL)")
            processDeepLink(testURL)
        }
    }
} 