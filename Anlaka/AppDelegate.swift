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

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate,
  MessagingDelegate
{
  
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {

    // Firebase 초기화를 가장 먼저 수행
    FirebaseApp.configure()
      UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
        DispatchQueue.main.async {
          if granted {
            // 권한이 허용되면 원격 알림 등록
              application.registerForRemoteNotifications()

          } else {
            print("❌ 푸시 알림 권한 거부됨")
              
            if let error = error {
              print("❌ 권한 요청 오류: \(error.localizedDescription)")
            }
          }
        }
      }
      
      // FCM 설정
      Messaging.messaging().delegate = self
    
      // UNUserNotificationCenter 설정
      UNUserNotificationCenter.current().delegate = self
    
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
    
    // 포그라운드에서도 알림 표시
    completionHandler([.banner, .sound, .badge])
  }
  
  // MARK: - 사용자가 알림을 탭했을 때 처리
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    print("📱 사용자가 알림 탭: \(response.notification.request.identifier)")
    
    // 알림 데이터 처리
    let userInfo = response.notification.request.content.userInfo
    print("📱 알림 데이터: \(userInfo)")
    
    completionHandler()
  }
}
