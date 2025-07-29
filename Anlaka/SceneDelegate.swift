import UIKit
import SwiftUI
import UserNotifications
import AudioToolbox
import os.log

class SceneDelegate: UIResponder, UIWindowSceneDelegate, UNUserNotificationCenterDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: [UIScene.ConnectionOptions]) {
        guard let windowScene = (scene as? UIWindowScene) else {
            return
        }
        
        window = UIWindow(windowScene: windowScene)
        let diContainer: DIContainer
        do {
            diContainer = try DIContainer.create()
        } catch {
            fatalError("DIContainer 생성 실패: \(error)")
        }
        
        let isLoggedIn = UserDefaults.standard.bool(forKey: TextResource.Global.isLoggedIn.text)
        
        // 토큰 갱신 상태 확인 및 동기화
        Task { @MainActor in
            await checkTokenRefreshStatus()
        }
        
        switchRootView(loggedIn: isLoggedIn, diContainer: diContainer)
        
        UNUserNotificationCenter.current().delegate = self
        restoreBadgeCount()
        updateAppIconBadge()
        setupLoginStateObserver()
        
        // 알림을 통해 앱이 실행된 경우 처리 - UserDefaults에만 저장하고 App에서 처리하도록 위임
        for option in connectionOptions {
            if let notificationResponse = option as? UNNotificationResponse {
                let userInfo = notificationResponse.notification.request.content.userInfo
                if isChatNotification(userInfo) {
                    let stringUserInfo = userInfo.compactMapKeys { $0 as? String }
                    if let roomId = stringUserInfo["room_id"] as? String {
                        UserDefaultsManager.shared.set(roomId, forKey: .pendingChatRoomId)
                    }
                }
                break
            }
        }
    }
    
    // MARK: - 토큰 갱신 상태 확인 및 동기화
    
    private func checkTokenRefreshStatus() async {
        // NetworkManager의 토큰 갱신 상태 확인
        let isRefreshing = await MainActor.run { TokenRefreshManager.shared.isCurrentlyRefreshing }
        let pendingCount = await MainActor.run { TokenRefreshManager.shared.pendingRequestCount }
        
        if isRefreshing {
            // 토큰 갱신 완료까지 대기 (최대 10초)
            for _ in 0..<20 {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초 대기
                
                let stillRefreshing = await MainActor.run { TokenRefreshManager.shared.isCurrentlyRefreshing }
                if !stillRefreshing {
                    break
                }
            }
        }
        
        // 토큰 유효성 최종 확인
        let now = Int(Date().timeIntervalSince1970)
        let accessExp = UserDefaultsManager.shared.getInt(forKey: .expAccess)
        let refreshExp = UserDefaultsManager.shared.getInt(forKey: .expRefresh)
        
        if now >= refreshExp {
            UserDefaults.standard.set(false, forKey: TextResource.Global.isLoggedIn.text)
        }
    }

    // 루트 뷰 컨트롤러를 교체하는 메서드
    func switchRootView(loggedIn: Bool, diContainer: DIContainer? = nil) {
        guard let windowScene = window?.windowScene ?? UIApplication.shared.connectedScenes.first(where: { $0 is UIWindowScene }) as? UIWindowScene else {
            return
        }
        
        if window == nil {
            window = UIWindow(windowScene: windowScene)
        }
        
        guard let window = window else {
            return
        }
        
        let di: DIContainer
        if let diContainer = diContainer {
            di = diContainer
        } else {
            do {
                di = try DIContainer.create()
            } catch {
                return
            }
        }
        
        DispatchQueue.main.async {
            window.rootViewController = loggedIn
                ? UIHostingController(rootView: MyTabView(di: di))
                : UIHostingController(rootView: LoginView(di: di))
            window.makeKeyAndVisible()
        }
    }
    
    // MARK: - Scene Lifecycle
    func sceneWillEnterForeground(_ scene: UIScene) {
        ChatNotificationCountManager.shared.debugBadgeStatus()
        NotificationCenter.default.post(name: .appDidEnterForeground, object: nil)
        
        // 뱃지 카운트 복원
        restoreBadgeCount()
        
        // 앱 아이콘 배지 업데이트
        updateAppIconBadge()
        
        // 포그라운드 진입 시 토큰 상태 확인
        Task { @MainActor in
            await checkTokenRefreshStatus()
        }
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // 백그라운드 진입 시 비활성 탭 캐시 정리
        Task { @MainActor in
            let currentTab = RoutingStateManager.shared.currentTab
            // RoutingStateManager.Tab을 MyTabView.Tab으로 변환
            let myTabViewTab = MyTabView.Tab(rawValue: currentTab.rawValue) ?? .home
            TabViewCache.shared.clearInactiveTabCaches(activeTab: myTabViewTab)
        }
    }
    
    // MARK: - Notification Handling
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        
        if isChatNotification(userInfo) {
            // 채팅 알림은 앱이 활성 상태일 때도 표시
            completionHandler([.banner, .sound, .badge])
        } else {
            // 일반 알림은 기본 옵션 사용
            completionHandler([.banner, .sound])
        }
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        if isChatNotification(userInfo) {
            let stringUserInfo = userInfo.compactMapKeys { $0 as? String }
            guard let roomId = stringUserInfo["room_id"] as? String else {
                completionHandler()
                return
            }
            
            // 임시 메시지 저장
            if let aps = userInfo["aps"] as? [String: Any],
               let alert = aps["alert"] as? [String: Any],
               let message = alert["body"] as? String,
               let senderName = alert["subtitle"] as? String {
                TemporaryLastMessageManager.shared.setTemporaryLastMessage(
                    roomId: roomId,
                    content: message,
                    senderId: stringUserInfo["google.c.sender.id"] as? String ?? "",
                    senderNick: senderName
                )
            }
            
            let isAppActive = UIApplication.shared.applicationState == .active
            
            if isAppActive {
                // 앱이 활성 상태면 UserDefaults에 저장하고 App에서 처리하도록 위임
                UserDefaultsManager.shared.set(roomId, forKey: .pendingChatRoomId)
            } else {
                UserDefaultsManager.shared.set(roomId, forKey: .pendingChatRoomId)
            }
        }
        
        completionHandler()
    }
    
    // MARK: - Helper Methods
    private var loginStateObserver: NSObjectProtocol?
    
    private func setupLoginStateObserver() {
        loginStateObserver = NotificationCenter.default.addObserver(
            forName: .loginStateChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let isLoggedIn = notification.userInfo?["isLoggedIn"] as? Bool else {
                return
            }
            
            self.switchRootView(loggedIn: isLoggedIn)
        }
    }
    
    private func restoreBadgeCount() {
        let badgeCount = UserDefaultsManager.shared.getInt(forKey: .badgeCount)
        UIApplication.shared.applicationIconBadgeNumber = badgeCount
    }
    
    private func updateAppIconBadge() {
        // 앱 아이콘 뱃지 업데이트 기능 주석처리
        // let totalBadgeCount = ChatNotificationCountManager.shared.getTotalBadgeCount()
        // UIApplication.shared.applicationIconBadgeNumber = totalBadgeCount
        // UserDefaultsManager.shared.set(totalBadgeCount, forKey: .badgeCount)
    }
    
    private func handleBackgroundNotificationData(_ userInfo: [AnyHashable: Any]) {
        let stringUserInfo = userInfo.compactMapKeys { $0 as? String }
        guard let roomId = stringUserInfo["room_id"] as? String else {
            return
        }
        
        // 임시 메시지 저장 (기존 로직 유지)
        if let aps = userInfo["aps"] as? [String: Any],
           let alert = aps["alert"] as? [String: Any],
           let message = alert["body"] as? String,
           let senderName = alert["subtitle"] as? String {
            TemporaryLastMessageManager.shared.setTemporaryLastMessage(
                roomId: roomId,
                content: message,
                senderId: stringUserInfo["google.c.sender.id"] as? String ?? "",
                senderNick: senderName
            )
        }
        
        let isLoggedIn = UserDefaults.standard.bool(forKey: TextResource.Global.isLoggedIn.text)
        
        if isLoggedIn {
            UserDefaultsManager.shared.set(roomId, forKey: .pendingChatRoomId)
        } else {
            UserDefaultsManager.shared.set(roomId, forKey: .pendingChatRoomId)
        }
    }
    
    private func isChatNotification(_ userInfo: [AnyHashable: Any]) -> Bool {
        let stringUserInfo = userInfo.compactMapKeys { $0 as? String }
        return stringUserInfo["room_id"] != nil
    }
    
    deinit {
        if let observer = loginStateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let loginStateChanged = Notification.Name("loginStateChanged")
    static let appDidEnterForeground = Notification.Name("appDidEnterForeground")
}
