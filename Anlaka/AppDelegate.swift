//
//  AppDelegate.swift
//  Anlaka
//
//  Created by 최정안 on 5/13/25.
//

import FirebaseCore
import FirebaseMessaging
import UIKit
import UserNotifications
import iamport_ios
import AudioToolbox

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate,
  MessagingDelegate
{
  
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {

    // Firebase 초기화를 가장 먼저 수행
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
        // 권한이 거부된 경우 앱 내 알림 시스템 활성화
        print("⚠️ 알림 권한이 거부되어 앱 내 알림 시스템을 사용합니다.")
    }
      
      // FCM 설정
      Messaging.messaging().delegate = self
    
      // UNUserNotificationCenter 설정
      UNUserNotificationCenter.current().delegate = self
      
      // 앱이 알림을 통해 실행된 경우 처리 (앱 완전 종료 상태)
      if let notification = launchOptions?[.remoteNotification] as? [String: Any] {
          print("📱 앱이 알림을 통해 실행됨 (완전 종료 상태): \(notification)")
          
          // 앱 완전 종료 상태에서 알림 처리
          handleNotificationData(notification)
          
          // 백그라운드 알림 처리도 함께 수행
          handleBackgroundNotification(notification)
      }
      
      // 앱 시작 시 배지 상태 확인 및 복원
      restoreBadgeCount()
    
    return true
    }

  
  // ✅ deviceToken 받는 콜백
  func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    // 디바이스 토큰을 16진수 문자열로 변환
    let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
    let token = tokenParts.joined()

  }
  func application(
    _ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    Iamport.shared.receivedURL(url)
    return true
  }

  // ❌ 등록 실패 시
  func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("❌ 푸시 등록 실패: \(error.localizedDescription)")
    print("❌ 에러 상세: \(error)")
    
    // 에러 타입별 상세 정보
    if let nsError = error as NSError? {
        print("❌ 에러 도메인: \(nsError.domain)")
        print("❌ 에러 코드: \(nsError.code)")
        print("❌ 에러 사용자 정보: \(nsError.userInfo)")
    }

  }


  
  // MARK: - MessagingDelegate
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("🔥 FCM 등록 토큰: \(fcmToken ?? "nil")")
        
        // FCM 토큰을 deviceToken으로 저장
        if let token = fcmToken {
            let existingToken = UserDefaultsManager.shared.getString(forKey: .deviceToken)
            
            if existingToken != token {
                print("🔥 FCM 토큰 변경 감지: \(existingToken ?? "nil") → \(token)")
                UserDefaultsManager.shared.set(token, forKey: .deviceToken)
                
                // 토큰 변경 플래그 설정
                UserDefaultsManager.shared.set(true, forKey: .deviceTokenChanged)
                

            }
        }
    }

  // MARK: - 앱이 포그라운드에 있을 때 알림 처리
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    print("📱 포그라운드에서 알림 수신: \(notification.request.identifier)")
    
    // 알림 데이터 처리
    let userInfo = notification.request.content.userInfo
    print("📱 포그라운드 알림 데이터: \(userInfo)")
    
            // 채팅 알림인지 확인
        if isChatNotification(userInfo) {
            // 포그라운드에서 채팅 알림 처리 (카운트 증가 포함)
            handleChatNotificationInForeground(userInfo)
            
            // 채팅 알림 업데이트 이벤트 전송
            NotificationCenter.default.post(name: .chatNotificationUpdate, object: nil)
            print("📱 포그라운드 채팅 알림 수신 - MyPageContainer에 이벤트 전송")
        
        // 채팅 알림인 경우: 커스텀 배너만 표시 (시스템 배너 숨김)
        // 사운드는 커스텀 배너에서만 재생하므로 시스템 사운드 비활성화
        completionHandler([.badge]) // .banner, .sound 제거
    } else {
        // 일반 알림인 경우: 배지 카운트 관리
        manageBadgeCount(userInfo)
        
        // 권한 상태에 따른 처리
        let permissionManager = NotificationPermissionManager.shared
        if permissionManager.isPermissionGranted {
            // 권한이 허용된 경우: 배너/사운드/배지 표시
            completionHandler([.banner, .sound, .badge])
        } else {
            // 권한이 거부된 경우: 커스텀 인앱 배너만 표시
            completionHandler([])
        }
    }
  }
  
  // MARK: - 백그라운드에서 원격 알림 수신 처리
  func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    print("📱 백그라운드에서 원격 알림 수신: \(userInfo)")
    
    // 앱이 백그라운드 상태일 때만 처리 (포그라운드에서는 willPresent에서 처리됨)
    if application.applicationState == .background {
        handleBackgroundNotification(userInfo)
        completionHandler(.newData)
    } else {
        print("📱 포그라운드에서 원격 알림 수신 - 이미 willPresent에서 처리됨")
        completionHandler(.noData)
    }
  }

  // MARK: - 백그라운드 알림 처리를 위한 별도 메서드
  private func handleBackgroundNotification(_ userInfo: [AnyHashable: Any]) {
    print("😡 백그라운드 알림 처리 시작")
    
    // 채팅 알림인지 확인
    if isChatNotification(userInfo) {
        print("📱 백그라운드 채팅 알림 처리")

        
        // 채팅 알림 카운트 증가 및 임시 마지막 메시지 저장
        if let chatData = parseChatNotificationData(userInfo) {
            ChatNotificationCountManager.shared.incrementCount(for: chatData.roomId)
            
            // 알림 body를 임시 마지막 메시지로 저장
            TemporaryLastMessageManager.shared.setTemporaryLastMessage(
                roomId: chatData.roomId,
                content: chatData.message,
                senderId: chatData.senderId,
                senderNick: chatData.senderId,
                hasFiles: false
            )
            
            // 채팅 알림 업데이트 이벤트 전송
            NotificationCenter.default.post(name: .chatNotificationUpdate, object: nil)
            print("📱 백그라운드 채팅 알림 수신 - MyPageContainer에 이벤트 전송")
        } else {
            print("⚠️ 백그라운드 채팅 알림 데이터 파싱 실패")
        }
    } else {
        print("📱 백그라운드 일반 알림 처리")
    }
  }
  
  // MARK: - 사용자가 알림을 탭했을 때 처리 (백그라운드 상태)
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    print("📱 백그라운드에서 알림 탭: \(response.notification.request.identifier)")
    
    // 알림 데이터 처리
    let userInfo = response.notification.request.content.userInfo
    print("📱 백그라운드 알림 데이터: \(userInfo)")
    
            // 채팅 알림인지 확인하고 처리
        if isChatNotification(userInfo) {
            print("📱 채팅 알림 감지 - 처리 시작")
            
            // 백그라운드 알림 데이터 처리 (카운트 증가 포함)
            handleBackgroundNotificationData(userInfo)
    } else {
        print("📱 일반 알림 - 채팅 알림이 아님")
    }
    
    completionHandler()
  }
  
  // MARK: - 채팅 알림 처리 메서드들
  
  /// 알림이 채팅 관련인지 확인
  private func isChatNotification(_ userInfo: [AnyHashable: Any]) -> Bool {
      // [AnyHashable: Any]를 [String: Any]로 변환
      let stringUserInfo = userInfo.compactMapKeys { $0 as? String }
      
      // 채팅 알림을 식별하는 키 확인
      // room_id 필드가 있어야만 채팅 알림으로 판단
      return stringUserInfo["room_id"] != nil
  }
  
  /// 알림 데이터를 파싱하여 ChatNotificationData로 변환
  private func parseChatNotificationData(_ userInfo: [AnyHashable: Any]) -> ChatNotificationData? {
      // [AnyHashable: Any]를 [String: Any]로 변환
      let stringUserInfo = userInfo.compactMapKeys { $0 as? String }
      
      // room_id 필드로 채팅방 ID 추출
      guard let roomId = stringUserInfo["room_id"] as? String else {
          print("❌ 채팅 알림 데이터 파싱 실패: room_id 필드 누락")
          return nil
      }
      
      // google.c.sender.id로 발신자 ID 추출
      guard let senderId = stringUserInfo["google.c.sender.id"] as? String else {
          print("❌ 채팅 알림 데이터 파싱 실패: google.c.sender.id 필드 누락")
          return nil
      }
      
      // aps.alert.body로 메시지 내용 추출
      guard let aps = userInfo["aps"] as? [String: Any],
            let alert = aps["alert"] as? [String: Any],
            let message = alert["body"] as? String else {
          print("❌ 채팅 알림 데이터 파싱 실패: aps.alert.body 필드 누락")
          return nil
      }
      
      // aps.alert.subtitle로 발신자 닉네임 추출
      guard let senderName = alert["subtitle"] as? String else {
          print("❌ 채팅 알림 데이터 파싱 실패: aps.alert.subtitle 필드 누락")
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
  
  /// 알림 데이터 처리 (앱 종료 상태에서 실행)
  private func handleNotificationData(_ userInfo: [AnyHashable: Any]) {
      print("📱 앱 완전 종료 상태에서 알림 데이터 처리 시작")
      
      // 1. 실제 알림 데이터 구조에 맞게 파싱
      let stringUserInfo = userInfo.compactMapKeys { $0 as? String }
      print("📱 알림 데이터: \(stringUserInfo)")
      
      // 2. room_id 필드로 채팅방 ID 추출
      guard let roomId = stringUserInfo["room_id"] as? String else {
          print("❌ 알림 데이터에서 room_id 파싱 실패")
          return
      }
      
      print("📱 채팅방 ID 추출 성공: \(roomId)")
      
      // 3. google.c.sender.id로 발신자 ID 추출
      guard let senderId = stringUserInfo["google.c.sender.id"] as? String else {
          print("❌ 알림 데이터에서 google.c.sender.id 파싱 실패")
          return
      }
      
      print("📱 발신자 ID 추출 성공: \(senderId)")
      
      // 4. 로그인 상태 확인
      let isLoggedIn = UserDefaults.standard.bool(forKey: TextResource.Global.isLoggedIn.text)
      print("📱 로그인 상태 확인: \(isLoggedIn)")
      
      if isLoggedIn {
          // 5. 로그인된 상태: 라우팅 큐에 등록하여 채팅방 이동
          Task { @MainActor in
              NotificationRoutingQueue.shared.enqueueChatRoom(roomId)
              print("📱 로그인 상태 - 라우팅 큐에 채팅방 등록 완료: \(roomId)")
          }
      } else {
          // 6. 로그인되지 않은 상태: 로그인 후 처리할 수 있도록 저장
          UserDefaultsManager.shared.set(roomId, forKey: .pendingChatRoomId)
          print("📱 비로그인 상태 - 채팅방 ID 저장 완료: \(roomId)")
      }
  }
  
  /// 알림 데이터 처리 (백그라운드 상태에서 실행)
  private func handleBackgroundNotificationData(_ userInfo: [AnyHashable: Any]) {
      print("📱 백그라운드 상태에서 알림 데이터 처리 시작")
      
      // 1. 채팅방 ID 추출
      let stringUserInfo = userInfo.compactMapKeys { $0 as? String }
      guard let roomId = stringUserInfo["room_id"] as? String else {
          print("❌ 백그라운드 알림에서 room_id 파싱 실패")
          return
      }
      
      print("📱 백그라운드 채팅방 ID 추출 성공: \(roomId)")
      
      // 2. 배지 카운트 관리
      manageBadgeCount(userInfo)
      
      // 3. 채팅 알림 카운트 증가 및 임시 메시지 설정 (중복 제거)
      // ChatNotificationCountManager.shared.incrementCount(for: roomId) // 이미 handleBackgroundNotification에서 처리됨
      
      // 4. 임시 마지막 메시지 설정 (알림 데이터에서 추출)
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
      
      // 5. 로그인 상태 확인
      let isLoggedIn = UserDefaults.standard.bool(forKey: TextResource.Global.isLoggedIn.text)
      print("📱 백그라운드 로그인 상태 확인: \(isLoggedIn)")
      
      if isLoggedIn {
          // 6. SwiftUI 상태 객체를 통한 화면 전환
          Task { @MainActor in
              // 라우팅 큐에 등록하여 화면 전환
              NotificationRoutingQueue.shared.enqueueChatRoom(roomId)
              print("📱 백그라운드 로그인 상태 - 라우팅 큐에 채팅방 등록 완료: \(roomId)")
              
              // 디버깅: 큐 상태 출력
              NotificationRoutingQueue.shared.printQueueStatus()
          }
      } else {
          // 7. 비로그인 상태: 로그인 후 처리할 수 있도록 저장
          UserDefaultsManager.shared.set(roomId, forKey: .pendingChatRoomId)
          print("📱 백그라운드 비로그인 상태 - 채팅방 ID 저장 완료: \(roomId)")
      }
  }
  
  /// 배지 카운트 관리 (iOS가 자동으로 처리하므로 로그만 출력)
  private func manageBadgeCount(_ userInfo: [AnyHashable: Any]) {
      // aps.badge 값 추출 (로그용)
      if let aps = userInfo["aps"] as? [String: Any],
         let badge = aps["badge"] as? Int {
          print("📱 서버 배지 값: \(badge) (iOS가 자동 처리)")
      } else {
          print("📱 서버 배지 값 없음 (iOS가 자동으로 +1)")
      }
  }
  
  /// 채팅 알림 카운트를 기반으로 앱 아이콘 배지 업데이트 (iOS가 자동 처리하므로 로그만 출력)
  private func updateAppIconBadge() {
      let totalCount = ChatNotificationCountManager.shared.totalCount
      print("📱 앱 내부 알림 카운트: \(totalCount) (iOS가 배지 자동 처리)")
  }
  
  /// 배지 카운트 초기화 (iOS가 자동으로 처리하므로 로그만 출력)
  private func resetBadgeCount() {
      print("📱 배지 카운트 초기화 (iOS가 자동 처리)")
  }
  
  /// 앱 시작 시 배지 상태 확인 (iOS가 자동으로 처리하므로 로그만 출력)
  private func restoreBadgeCount() {
      let totalCount = ChatNotificationCountManager.shared.totalCount
      print("📱 앱 시작 시 내부 알림 카운트: \(totalCount) (iOS가 배지 자동 처리)")
      
      // 디버깅 정보 출력
      ChatNotificationCountManager.shared.debugBadgeStatus()
  }
  
  /// 포그라운드에서 채팅 알림 처리
  private func handleChatNotificationInForeground(_ userInfo: [AnyHashable: Any]) {
      print("📱 포그라운드에서 채팅 알림 처리")
      
      guard let chatData = parseChatNotificationData(userInfo) else {
          return
      }
      
      let permissionManager = NotificationPermissionManager.shared
      
      // 채팅방 내부에서 알림 사운드 재생 여부 확인
      let shouldPlaySound = !isInChatRoom(roomId: chatData.roomId)
      
      // 다른 탭/화면에서는 사운드 재생
      if shouldPlaySound {
          playNotificationSound()
      }
      
      // 채팅 알림 카운트 증가 및 임시 메시지 설정
      ChatNotificationCountManager.shared.incrementCount(for: chatData.roomId)
      TemporaryLastMessageManager.shared.setTemporaryLastMessage(
          roomId: chatData.roomId,
          content: chatData.message,
          senderId: chatData.senderId,
          senderNick: chatData.senderName
      )
      
      if permissionManager.isPermissionGranted {
          // 권한이 허용된 경우: 시스템 알림 표시 (단, 채팅방 내부에서는 사운드 없음)
          print("📱 포그라운드 채팅 알림 (시스템): \(chatData.message)")
          
          // 시스템 알림과 함께 커스텀 인앱 배너도 표시
          Task { @MainActor in
              InAppNotificationManager.shared.addChatNotification(
                  roomId: chatData.roomId,
                  senderName: chatData.senderName,
                  message: chatData.message
              ) {
                  // 알림 탭 시 채팅방으로 이동
                  NotificationRoutingQueue.shared.enqueueChatRoom(chatData.roomId)
              }
          }
      } else {
          // 권한이 거부된 경우: 커스텀 인앱 배너만 표시
          Task { @MainActor in
              InAppNotificationManager.shared.addChatNotification(
                  roomId: chatData.roomId,
                  senderName: chatData.senderName,
                  message: chatData.message
              ) {
                  // 알림 탭 시 채팅방으로 이동
                  NotificationRoutingQueue.shared.enqueueChatRoom(chatData.roomId)
              }
          }
          print("📱 포그라운드 채팅 알림 (커스텀 인앱 배너): \(chatData.message)")
      }
  }
  
  /// 현재 채팅방 내부에 있는지 확인
  private func isInChatRoom(roomId: String) -> Bool {
      // CurrentScreenTracker를 사용하여 현재 화면 상태 확인
      return CurrentScreenTracker.shared.isInSpecificChatRoom(roomId: roomId)
  }
  
  /// 알림 사운드 재생
  private func playNotificationSound() {
      // 시스템 기본 알림 사운드 재생
      AudioServicesPlaySystemSound(1007) // 시스템 알림 사운드
      print("📱 알림 사운드 재생")
  }
  
  /// 강제 배지 업데이트 (디버깅용 - iOS가 자동 처리하므로 로그만 출력)
  private func forceUpdateBadge() {
      let totalCount = ChatNotificationCountManager.shared.totalCount
      print("🔧 내부 알림 카운트: \(totalCount) (iOS가 배지 자동 처리)")
  }
  
  // MARK: - 앱 생명주기 관리
  func applicationWillEnterForeground(_ application: UIApplication) {
      print("📱 앱이 포그라운드로 진입")
      
      // 디버깅 정보 출력
      ChatNotificationCountManager.shared.debugBadgeStatus()
      
      // 포그라운드 진입 시 UI 업데이트 트리거
      NotificationCenter.default.post(name: .appDidEnterForeground, object: nil)
  }
  
  func applicationDidEnterBackground(_ application: UIApplication) {
      print("📱 앱이 백그라운드로 진입")
  }
  
  /// 백그라운드 알림 테스트용 (디버깅용)
  private func testBackgroundNotification() {
      print("🔧 백그라운드 알림 테스트 시작")
      
      // 테스트용 채팅 알림 데이터
      let testUserInfo: [String: Any] = [
          "room_id": "test_room_123",
          "google.c.sender.id": "test_sender",
          "aps": [
              "alert": [
                  "body": "테스트 메시지",
                  "subtitle": "테스트 발신자"
              ]
          ]
      ]
      
      handleBackgroundNotification(testUserInfo)
      print("🔧 백그라운드 알림 테스트 완료")
  }
}

// MARK: - NotificationCenter 확장
extension Notification.Name {
    static let appDidEnterForeground = Notification.Name("appDidEnterForeground")
    static let chatNotificationUpdate = Notification.Name("chatNotificationUpdate")
}

// MARK: - Dictionary 확장
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
