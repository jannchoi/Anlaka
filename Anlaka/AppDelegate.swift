import FirebaseCore
import FirebaseMessaging
import UIKit
import UserNotifications
import iamport_ios

class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Firebase 초기화
        FirebaseApp.configure()
        
        // 알림 권한 관리자 초기화
        let permissionManager = NotificationPermissionManager.shared
        
        // 권한이 필요한 경우에만 요청
        if permissionManager.needsPermissionRequest {
            Task {
                let granted = await permissionManager.requestNotificationPermission()
                if granted {
                    // 권한이 허용되면 원격 알림 등록
                    application.registerForRemoteNotifications()
                }
            }
        } else if permissionManager.isPermissionGranted {
            // 이미 권한이 허용된 경우 원격 알림 등록
            application.registerForRemoteNotifications()
        } else if permissionManager.isPermissionDenied {
            // 앱 내 알림 시스템 사용
        }
        
        // FCM 설정
        Messaging.messaging().delegate = self
        
        return true
    }
        func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
    
    let sceneConfig = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    sceneConfig.delegateClass = SceneDelegate.self // SceneDelegate 연결
    
    return sceneConfig
}
    
    // MARK: - Remote Notification Registration
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("❌ 푸시 등록 실패: \(error.localizedDescription)")
        if let nsError = error as NSError? {
            print("❌ 에러 도메인: \(nsError.domain), 코드: \(nsError.code), 정보: \(nsError.userInfo)")
        }
    }
    
    // MARK: - URL Handling
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        Iamport.shared.receivedURL(url)
        return true
    }
    
    // MARK: - MessagingDelegate
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("디바이스 토큰: \(fcmToken ?? "nil")")
        if let token = fcmToken {
            let existingToken = UserDefaultsManager.shared.getString(forKey: .deviceToken)
            if existingToken != token {
                print("디바이스 변경 감지: \(existingToken ?? "nil") → \(token)")
                UserDefaultsManager.shared.set(token, forKey: .deviceToken)
                UserDefaultsManager.shared.set(true, forKey: .deviceTokenChanged)
            }
        }
    }

    // MARK: - Helper Methods
    private func isChatNotification(_ userInfo: [AnyHashable: Any]) -> Bool {
        let stringUserInfo = userInfo.compactMapKeys { $0 as? String }
        return stringUserInfo["room_id"] != nil
    }
    
    private func parseChatNotificationData(_ userInfo: [AnyHashable: Any]) -> ChatNotificationData? {
        let stringUserInfo = userInfo.compactMapKeys { $0 as? String }
        
        // room_id 검사
        guard let roomId = stringUserInfo["room_id"] as? String, !roomId.isEmpty else {
            return nil
        }
        
        // sender_id 검사
        guard let senderId = stringUserInfo["google.c.sender.id"] as? String, !senderId.isEmpty else {
            return nil
        }
        
        // aps.alert.body 검사
        guard let aps = userInfo["aps"] as? [String: Any],
              let alert = aps["alert"] as? [String: Any],
              let message = alert["body"] as? String, !message.isEmpty else {
            return nil
        }
        
        // aps.alert.subtitle 검사
        guard let senderName = alert["subtitle"] as? String, !senderName.isEmpty else {
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

    private func saveNotificationData(_ chatData: ChatNotificationData) {
        let sharedDefaults = UserDefaults(suiteName: "group.com.jann.Anlaka")
        var notifications = sharedDefaults?.array(forKey: "notifications") as? [[String: Any]] ?? []
        let notificationData = [
            "room_id": chatData.roomId,
            "subtitle": chatData.senderName,
            "body": chatData.message,
            "timestamp": chatData.timestamp.timeIntervalSince1970
        ] as [String: Any]
        notifications.append(notificationData)
        sharedDefaults?.set(notifications, forKey: "notifications")
    }
    

}

// MARK: - NotificationCenter Extension
extension Notification.Name {
    static let chatNotificationUpdate = Notification.Name("chatNotificationUpdate")
}

// MARK: - Dictionary Extension
extension Dictionary {
    func compactMapKeys<T>(_ transform: (Key) throws -> T?) rethrows -> [T: Value] {
        var result: [T: Value] = [:]
        for (key, value) in self {
            if let transformedKey = try transform(key) {
                result[transformedKey] = value
            }
        }
        return result
    }
}

// extension AppDelegate {
//     // MARK: - Background Notification Handling
//     // content-available이 없어서 백그라운드에서 호출되지 않음
//     func application(
//         _ application: UIApplication,
//         didReceiveRemoteNotification userInfo: [AnyHashable: Any],
//         fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
//     ) {
//         // 백그라운드에서만 처리 (포그라운드는 SceneDelegate에서 처리)
//         if application.applicationState == .background && isChatNotification(userInfo) {
//             handleBackgroundNotification(userInfo)
//             completionHandler(.newData)
//         } else {
//             completionHandler(.noData)
//         }
//     }
    
//     // MARK: - Background Notification Processing
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

//                 // 4. 알림 데이터 저장
//                 saveNotificationData(chatData)
//             }
//         }
//     }
    
//     // MARK: - Notification Data Processing (App Terminated)
//     // content-available이 없어서 앱 종료 시 호출되지 않음
//     private func handleNotificationData(_ userInfo: [AnyHashable: Any]) {
//         print("앱 완전 종료 상태에서 알림 데이터 처리 시작")
//         let stringUserInfo = userInfo.compactMapKeys { $0 as? String }
//         guard let roomId = stringUserInfo["room_id"] as? String else {
//             print("❌ 알림 데이터에서 room_id 파싱 실패")
//             return
//         }
//         print("채팅방 ID 추출 성공: \(roomId)")
        
//         guard let senderId = stringUserInfo["google.c.sender.id"] as? String else {
//             print("❌ 알림 데이터에서 google.c.sender.id 파싱 실패")
//             return
//         }
//         print("발신자 ID 추출 성공: \(senderId)")
        
//         let isLoggedIn = UserDefaults.standard.bool(forKey: TextResource.Global.isLoggedIn.text)
//         print("로그인 상태 확인: \(isLoggedIn)")
        
//         if isLoggedIn {
//             Task { @MainActor in
//                 NotificationRoutingQueue.shared.enqueueChatRoom(roomId)
//                 print("로그인 상태 - 라우팅 큐에 채팅방 등록 완료: \(roomId)")
//             }
//         } else {
//             UserDefaultsManager.shared.set(roomId, forKey: .pendingChatRoomId)
//             print("비로그인 상태 - 채팅방 ID 저장 완료: \(roomId)")
//         }
//     }
// }
