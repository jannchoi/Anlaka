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

    // FCM 설정
    Messaging.messaging().delegate = self

    // 푸시 알림 설정
    UNUserNotificationCenter.current().delegate = self

    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
    UNUserNotificationCenter.current().requestAuthorization(options: authOptions) {
      granted, error in
      if granted {
        DispatchQueue.main.async {
          UIApplication.shared.registerForRemoteNotifications()
        }
      } else {
        print("🔕 알림 권한 거부됨")
      }
    }

    return true
  }

  // ✅ deviceToken 받는 콜백
  func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
    let tokenString = tokenParts.joined()
    print("📲 deviceToken: \(tokenString)")

    // FCM에 APNs 토큰 설정
    Messaging.messaging().apnsToken = deviceToken

    // UserDefaults에 저장
    UserDefaultsManager.shared.set(tokenString, forKey: .deviceToken)

    // APNs 토큰이 설정된 후에 FCM 토큰 요청
    Messaging.messaging().token { token, error in
      if let error = error {
        print("Error fetching FCM registration token: \(error)")
      } else if let token = token {
        print("FCM registration token: \(token)")
        // FCM 토큰을 UserDefaults에 저장
        UserDefaultsManager.shared.set(token, forKey: .fcmToken)
      }
    }
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
  }

  // MARK: - MessagingDelegate
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("Firebase registration token: \(String(describing: fcmToken))")
    if let token = fcmToken {
      UserDefaultsManager.shared.set(token, forKey: .fcmToken)
    }
  }
}
