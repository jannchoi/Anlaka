//
//  AppDelegate.swift
//  Anlaka
//
//  Created by 최정안 on 5/13/25.
//

import UIKit
import UserNotifications


class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
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
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let tokenString = tokenParts.joined()
        print("📲 deviceToken: \(tokenString)")
        
        // 👉 예: UserDefaults에 저장
        UserDefaultsManager.shared.set(tokenString, forKey: .deviceToken)
    }

    // ❌ 등록 실패 시
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ 푸시 등록 실패: \(error.localizedDescription)")
    }
}

