import UIKit
import SwiftUI
import UserNotifications
import AudioToolbox
import os.log

class SceneDelegate: UIResponder, UIWindowSceneDelegate, UNUserNotificationCenterDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: [UIScene.ConnectionOptions]) {
        guard let windowScene = (scene as? UIWindowScene) else {
            print("❌ windowScene 변환 실패")
            return
        }
        print("📱 windowScene 생성 성공")
        
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
                        print("🔔 앱 시작 시 알림 - 대기 중인 딥링크 저장: \(roomId)")
                    }
                }
                break
            }
        }
    }
    
    // MARK: - 토큰 갱신 상태 확인 및 동기화
    
    private func checkTokenRefreshStatus() async {
        print("🔍 토큰 갱신 상태 확인 중...")
        
        // NetworkManager의 토큰 갱신 상태 확인
        let isRefreshing = await MainActor.run { TokenRefreshManager.shared.isCurrentlyRefreshing }
        let pendingCount = await MainActor.run { TokenRefreshManager.shared.pendingRequestCount }
        
        if isRefreshing {
            print("⏳ 토큰 갱신이 진행 중입니다 - 대기 중인 요청: \(pendingCount)개")
            
            // 토큰 갱신 완료까지 대기 (최대 10초)
            for _ in 0..<20 {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초 대기
                
                let stillRefreshing = await MainActor.run { TokenRefreshManager.shared.isCurrentlyRefreshing }
                if !stillRefreshing {
                    print("✅ 토큰 갱신 완료")
                    break
                }
            }
        }
        
        // 토큰 유효성 최종 확인
        let now = Int(Date().timeIntervalSince1970)
        let accessExp = UserDefaultsManager.shared.getInt(forKey: .expAccess)
        let refreshExp = UserDefaultsManager.shared.getInt(forKey: .expRefresh)
        
        if now >= refreshExp {
            print("🔐 Refresh Token 만료 - 로그인 상태 무효화")
            UserDefaults.standard.set(false, forKey: TextResource.Global.isLoggedIn.text)
        } else if now >= accessExp {
            print("⚠️ Access Token 만료 - 갱신 필요")
        } else {
            print("✅ 토큰 상태 정상")
        }
    }

    // 루트 뷰 컨트롤러를 교체하는 메서드
    func switchRootView(loggedIn: Bool, diContainer: DIContainer? = nil) {
        guard let windowScene = window?.windowScene ?? UIApplication.shared.connectedScenes.first(where: { $0 is UIWindowScene }) as? UIWindowScene else {
            print("❌ windowScene을 찾을 수 없음")
            return
        }
        
        if window == nil {
            window = UIWindow(windowScene: windowScene)
            print("📱 window 새로 초기화")
        }
        
        guard let window = window else {
            print("❌ window가 nil")
            return
        }
        
        let di: DIContainer
        if let diContainer = diContainer {
            di = diContainer
        } else {
            do {
                di = try DIContainer.create()
            } catch {
                print("❌ DIContainer 생성 실패: \(error)")
                return
            }
        }
        
        DispatchQueue.main.async {
            window.rootViewController = loggedIn
                ? UIHostingController(rootView: MyTabView(di: di))
                : UIHostingController(rootView: LoginView(di: di))
            window.makeKeyAndVisible()
            print("🔐 루트 뷰 전환 완료: \(loggedIn ? "MyTabView" : "LoginView")")
        }
    }
    
    // MARK: - Scene Lifecycle
    func sceneWillEnterForeground(_ scene: UIScene) {
        print("📱 앱이 포그라운드로 진입 - SceneDelegate")

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
        print("📱 앱이 백그라운드로 진입 - SceneDelegate")
        
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
            print("🔔 알림 탭 - 앱 상태: \(isAppActive ? "활성" : "백그라운드"), 채팅방: \(roomId)")
            
            if isAppActive {
                // 앱이 활성 상태면 UserDefaults에 저장하고 App에서 처리하도록 위임
                UserDefaultsManager.shared.set(roomId, forKey: .pendingChatRoomId)
                print("🔔 활성 상태 알림 - 대기 중인 딥링크 저장: \(roomId)")
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
            
            print("🔐 SceneDelegate에서 로그인 상태 변경 감지: \(isLoggedIn)")
            self.switchRootView(loggedIn: isLoggedIn)
        }
    }
    
    private func restoreBadgeCount() {
        let badgeCount = UserDefaultsManager.shared.getInt(forKey: .badgeCount)
        UIApplication.shared.applicationIconBadgeNumber = badgeCount
        print("📱 뱃지 카운트 복원: \(badgeCount)")
    }
    
    private func updateAppIconBadge() {
//        let totalBadgeCount = ChatNotificationCountManager.shared.getTotalBadgeCount()
//        UIApplication.shared.applicationIconBadgeNumber = totalBadgeCount
//        UserDefaultsManager.shared.set(totalBadgeCount, forKey: .badgeCount)
//        print("📱 앱 아이콘 배지 업데이트: \(totalBadgeCount)")
    }
    
    private func handleBackgroundNotificationData(_ userInfo: [AnyHashable: Any]) {
        print("📱 백그라운드 상태에서 알림 데이터 처리 시작")
        let stringUserInfo = userInfo.compactMapKeys { $0 as? String }
        guard let roomId = stringUserInfo["room_id"] as? String else {
            print("❌ 백그라운드 알림에서 room_id 파싱 실패")
            return
        }
        print("📱 백그라운드 채팅방 ID 추출 성공: \(roomId)")
        
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
        print("📱 백그라운드 로그인 상태 확인: \(isLoggedIn)")
        
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
