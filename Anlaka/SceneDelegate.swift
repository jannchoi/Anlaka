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
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        print("📱 앱이 백그라운드로 진입 - SceneDelegate")
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        print("📱 앱이 활성화됨 - SceneDelegate")
        
        // window가 설정되지 않았다면 여기서 설정
        if window == nil {
            print("📱 SceneDelegate window가 nil - 초기화 수행")
            guard let windowScene = (scene as? UIWindowScene) else { 
                print("❌ SceneDelegate windowScene 변환 실패")
                return 
            }
            print("📱 SceneDelegate windowScene 생성 성공")
            
            window = UIWindow(windowScene: windowScene)
            
            // DIContainer 생성
            let diContainer: DIContainer
            do {
                diContainer = try DIContainer.create()
            } catch {
                fatalError("DIContainer 생성 실패: \(error)")
            }
            
            // 초기 화면 설정 (SwiftUI가 이후 화면 전환 담당)
            setupInitialView()
            window?.makeKeyAndVisible()
            print("📱 SceneDelegate UIWindow 설정 완료")
            
            // UNUserNotificationCenter delegate 설정
            UNUserNotificationCenter.current().delegate = self
            print("📱 UNUserNotificationCenter delegate 설정 완료")
            
            // 현재 delegate 확인
            let currentDelegate = UNUserNotificationCenter.current().delegate
            print("📱 현재 UNUserNotificationCenter delegate: \(String(describing: currentDelegate))")
            print("📱 SceneDelegate 인스턴스: \(self)")
            print("📱 delegate 일치 여부: \(currentDelegate === self)")
            
            // 알림 권한 상태 확인
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                print("📱 알림 권한 상태: \(settings.authorizationStatus.rawValue)")
                print("📱 알림 표시 권한: \(settings.alertSetting.rawValue)")
                print("📱 배지 권한: \(settings.badgeSetting.rawValue)")
                print("📱 사운드 권한: \(settings.soundSetting.rawValue)")
            }
            
            // 앱 시작 시 배지 상태 복원
            restoreBadgeCount()
            
            // 앱 아이콘 배지 업데이트
            updateAppIconBadge()
        } else {
            // 앱이 이미 실행 중이고 백그라운드에서 포그라운드로 전환된 경우
            // App의 ContentView에서 처리하도록 위임 (UserDefaults에 저장된 상태를 App이 확인)
            print("🔄 백그라운드→포그라운드 - App에서 대기 중인 딥링크 처리")
        }
    }
    
func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
) {
    print("📱 ===== 포그라운드 알림 수신 시작 =====")
    print("📱 알림 ID: \(notification.request.identifier)")
    print("📱 앱 상태: \(UIApplication.shared.applicationState.rawValue)")
    let userInfo = notification.request.content.userInfo
    print("📱 포그라운드 알림 데이터: \(userInfo)")
    
    if isChatNotification(userInfo) {
        print("📱 포그라운드 채팅 알림 처리 시작")
        
        // 포그라운드 채팅 알림 처리 (카운트 증가, 임시 메시지 저장)
        handleChatNotificationInForeground(userInfo)
        
        // MyPageContainer 업데이트 트리거 (한 번만)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .chatNotificationUpdate, object: nil)
            print("📱 포그라운드 채팅 알림 - MyPageContainer 업데이트 트리거")
        }
        
        // 새로운 커스텀 알림 시스템 사용
        if let chatData = parseChatNotificationData(userInfo) {
            DispatchQueue.main.async {
                CustomNotificationManager.shared.handleNewNotification(
                    roomId: chatData.roomId,
                    senderName: chatData.senderName,
                    message: chatData.message
                )
            }
            print("📱 포그라운드 커스텀 알림 처리: \(chatData.message)")
        }
        
        // 시스템 배너 숨김 (badge, sound만 허용)
        completionHandler([.badge, .sound])
    } else {
        print("📱 포그라운드 일반 알림 처리")
        // ChatNotificationCountManager가 배지 카운트를 관리하므로 제거
        // manageBadgeCount(userInfo)
        let permissionManager = NotificationPermissionManager.shared
        if permissionManager.isPermissionGranted {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.badge])
        }
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
    
    /// 로그인 상태 변경 감지 설정 (초기 설정만)
    private func setupLoginStateObserver() {
        // 초기 설정 후에는 SwiftUI가 화면 전환을 담당하므로 옵저버 제거
        print("🔐 SceneDelegate - 초기 설정 완료, 이후 SwiftUI가 화면 전환 담당")
    }
    
    /// 초기 화면 설정 (앱 시작 시에만 사용)
    private func setupInitialView() {
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0 is UIWindowScene }) as? UIWindowScene else {
            print("❌ SceneDelegate - windowScene을 찾을 수 없음")
            return
        }
        
        if window == nil {
            window = UIWindow(windowScene: windowScene)
        }
        
        guard let window = window else {
            print("❌ SceneDelegate - window가 여전히 nil")
            return
        }
        
        let diContainer: DIContainer
        do {
            diContainer = try DIContainer.create()
        } catch {
            print("❌ DIContainer 생성 실패: \(error)")
            return
        }
        
        // 초기 화면을 ContentView로 설정 (SwiftUI가 화면 전환 담당)
        window.rootViewController = UIHostingController(rootView: ContentView())
        window.makeKeyAndVisible()
        print("🔐 SceneDelegate - 초기 화면을 ContentView로 설정")
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
    
    private func parseChatNotificationData(_ userInfo: [AnyHashable: Any]) -> ChatNotificationData? {
        let stringUserInfo = userInfo.compactMapKeys { $0 as? String }
        
        // room_id 검사
        guard let roomId = stringUserInfo["room_id"] as? String, !roomId.isEmpty else {
            print("❌ 채팅 알림 데이터 파싱 실패: room_id 필드 누락 또는 빈 문자열")
            return nil
        }
        
        // sender_id 검사
        guard let senderId = stringUserInfo["google.c.sender.id"] as? String, !senderId.isEmpty else {
            print("❌ 채팅 알림 데이터 파싱 실패: google.c.sender.id 필드 누락 또는 빈 문자열")
            return nil
        }
        
        // aps.alert.body 검사
        guard let aps = userInfo["aps"] as? [String: Any],
              let alert = aps["alert"] as? [String: Any],
              let message = alert["body"] as? String, !message.isEmpty else {
            print("❌ 채팅 알림 데이터 파싱 실패: aps.alert.body 필드 누락 또는 빈 문자열")
            return nil
        }
        
        // aps.alert.subtitle 검사
        guard let senderName = alert["subtitle"] as? String, !senderName.isEmpty else {
            print("❌ 채팅 알림 데이터 파싱 실패: aps.alert.subtitle 필드 누락 또는 빈 문자열")
            return nil
        }
        
        let timestamp = Date()
        return ChatNotificationData(
            roomId: roomId,
            senderId: senderId,
            senderName: senderName,
            message: message,
            timestamp: timestamp,
            notificationType: .newMessage
        )
    }
    
    // ChatNotificationCountManager가 배지 카운트를 관리하므로 제거
    // private func manageBadgeCount(_ userInfo: [AnyHashable: Any]) { ... }
    
    private func restoreBadgeCount() {
        // ChatNotificationCountManager에서 배지 상태 복원
        let totalCount = ChatNotificationCountManager.shared.totalCount
        UIApplication.shared.applicationIconBadgeNumber = totalCount
        print("📱 앱 시작 시 뱃지 복원: \(totalCount)")
        
        // 디버깅을 위해 현재 상태 출력
        print("📱 === 앱 시작 시 배지 상태 ===")
        print("📱 ChatNotificationCountManager 총 카운트: \(totalCount)")
        print("📱 앱 아이콘 배지: \(UIApplication.shared.applicationIconBadgeNumber)")
        ChatNotificationCountManager.shared.debugBadgeStatus()
        print("📱 =========================")
    }
    
    private func handleChatNotificationInForeground(_ userInfo: [AnyHashable: Any]) {
        print("📱 ===== 포그라운드 채팅 알림 처리 시작 =====")
        print("📱 입력 데이터: \(userInfo)")
        
        guard let chatData = parseChatNotificationData(userInfo) else { 
            print("❌ 포그라운드 채팅 알림 데이터 파싱 실패")
            print("📱 파싱 실패한 데이터: \(userInfo)")
            return 
        }
        
        print("📱 포그라운드 채팅 데이터 파싱 성공: \(chatData.roomId)")
        print("📱 메시지: \(chatData.message)")
        print("📱 발신자: \(chatData.senderName)")
        
        let permissionManager = NotificationPermissionManager.shared
        let shouldPlaySound = !isInChatRoom(roomId: chatData.roomId)
        
        if shouldPlaySound {
            playNotificationSound()
            print("📱 포그라운드 알림 사운드 재생")
        }
        
        // 1. 알림 카운트 증가
        let beforeCount = ChatNotificationCountManager.shared.getCount(for: chatData.roomId)
        ChatNotificationCountManager.shared.incrementCount(for: chatData.roomId)
        let afterCount = ChatNotificationCountManager.shared.getCount(for: chatData.roomId)
        print("📱 포그라운드 알림 카운트 증가: \(beforeCount) → \(afterCount)")
        print("📱 총 알림 카운트: \(ChatNotificationCountManager.shared.totalCount)")
        
        // 2. 임시 마지막 메시지 저장
        TemporaryLastMessageManager.shared.setTemporaryLastMessage(
            roomId: chatData.roomId,
            content: chatData.message,
            senderId: chatData.senderId,
            senderNick: chatData.senderName
        )
        print("📱 포그라운드 임시 메시지 저장 완료")
        
        // 3. 앱 아이콘 배지 업데이트
        updateAppIconBadge()
        
        // 4. 딥링크 URL 생성 (포그라운드에서는 즉시 처리하지 않고 알림만 표시)
        _ = DeepLinkScheme.createURL(type: .chat, id: chatData.roomId, source: .pushNotification)
    }
    
    private func isInChatRoom(roomId: String) -> Bool {
        return CurrentScreenTracker.shared.isInSpecificChatRoom(roomId: roomId)
    }
    
    private func updateAppIconBadge() {
        let totalCount = ChatNotificationCountManager.shared.totalCount
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = totalCount
        }
        print("📱 앱 아이콘 배지 업데이트: \(totalCount)")
    }
    
    private func playNotificationSound() {
        AudioServicesPlaySystemSound(1007)
        print("📱 알림 사운드 재생")
    }
    
    /// 테스트용 포그라운드 알림 시뮬레이션
    func simulateForegroundNotification() {
        let testUserInfo: [AnyHashable: Any] = [
            "room_id": "test_room_123",
            "google.c.sender.id": "sender_456",
            "aps": [
                "alert": [
                    "body": "테스트 메시지입니다",
                    "subtitle": "테스트 사용자"
                ]
            ]
        ]
        
        print("📱 ===== 테스트 포그라운드 알림 시뮬레이션 =====")
        handleChatNotificationInForeground(testUserInfo)
    }
    
    /// 테스트용 로컬 알림 전송
    func sendTestLocalNotification() {
        let content = UNMutableNotificationContent()
        content.title = "테스트 알림"
        content.body = "이것은 테스트 알림입니다"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "test_notification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 로컬 알림 전송 실패: \(error)")
            } else {
                print("📱 로컬 알림 전송 성공")
            }
        }
    }
}



// extension SceneDelegate {
//     // content-available이 없어서 백그라운드에서 호출되지 않음
//     private func handleBackgroundNotification(_ userInfo: [AnyHashable: Any]) {
//         if isChatNotification(userInfo) {
//             if let chatData = parseChatNotificationData(userInfo) {
//                 // 1. 알림 카운트 증가
//                 ChatNotificationCountManager.shared.incrementCount(for: chatData.roomId)
                
//                 // 2. 임시 마지막 메시지 저장
//                 TemporaryLastMessageManager.shared.setTemporaryLastMessage(
//                     roomId: chatData.roomId,
//                     content: chatData.message,
//                     senderId: chatData.senderId,
//                     senderNick: chatData.senderName,
//                     hasFiles: false
//                 )
                
//                 // 3. 앱 아이콘 배지 업데이트
//                 let totalCount = ChatNotificationCountManager.shared.totalCount
//                 DispatchQueue.main.async {
//                     UIApplication.shared.applicationIconBadgeNumber = totalCount
//                 }
                
//                 NotificationCenter.default.post(name: .chatNotificationUpdate, object: nil)
//             }
//         }
//     }
// content-available이 없어서 백그라운드에서 호출되지 않음
// func scene(_ scene: UIScene, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
//     os_log(.debug, "📱 [%{public}@] SceneDelegate 백그라운드 알림 수신: %@", Date().description, "\(userInfo)")
//     os_log(.debug, "📱 userInfo keys: %@", "\(userInfo.keys)")
//     os_log(.debug, "📱 isChatNotification: %d", isChatNotification(userInfo))
//     if UIApplication.shared.applicationState == .background {
//         if let chatData = parseChatNotificationData(userInfo) {
//             os_log(.debug, "📱 파싱된 데이터: roomId=%@, message=%@", chatData.roomId, chatData.message)
//             let beforeCount = ChatNotificationCountManager.shared.getCount(for: chatData.roomId)
//             ChatNotificationCountManager.shared.incrementCount(for: chatData.roomId)
//             let afterCount = ChatNotificationCountManager.shared.getCount(for: chatData.roomId)
//             os_log(.debug, "📱 카운트 변경: %d -> %d", beforeCount, afterCount)
//             os_log(.debug, "📱 총 카운트: %d", ChatNotificationCountManager.shared.totalCount)
//         } else {
//             os_log(.error, "❌ 채팅 데이터 파싱 실패")
//         }
//         completionHandler(.newData)
//     } else {
//         os_log(.debug, "📱 포그라운드 또는 비활성 상태 - 처리 생략")
//         completionHandler(.noData)
//     }
// }
// }