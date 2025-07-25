//
//  NotificationPermissionManager.swift
//  Anlaka
//
//  Created by 최정안 on 5/13/25.
//

import Foundation
import UserNotifications
import SwiftUI

// MARK: - 알림 권한 상태
enum NotificationPermissionStatus {
    case authorized
    case denied
    case notDetermined
    case provisional
    case ephemeral
    case unknown
}

// MARK: - 알림 권한 관리자
@MainActor
class NotificationPermissionManager: ObservableObject {
    static let shared = NotificationPermissionManager()
    
    @Published var permissionStatus: NotificationPermissionStatus = .unknown
    @Published var shouldShowPermissionAlert = false
    @Published var permissionAlertMessage = ""
    
    private init() {
        checkCurrentPermissionStatus()
    }
    
    /// 현재 알림 권한 상태 확인
    func checkCurrentPermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.updatePermissionStatus(settings)
            }
        }
    }
    
    /// 알림 권한 요청
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            
            await MainActor.run {
                if granted {
                    self.permissionStatus = .authorized
                    self.shouldShowPermissionAlert = false
                    print("알림 권한 허용됨")
                } else {
                    self.permissionStatus = .denied
                    self.showPermissionDeniedAlert()
                    print("❌ 알림 권한 거부됨")
                }
            }
            
            return granted
        } catch {
            await MainActor.run {
                self.permissionStatus = .unknown
                self.showPermissionErrorAlert(error.localizedDescription)
                print("❌ 알림 권한 요청 오류: \(error.localizedDescription)")
            }
            return false
        }
    }
    
    /// 권한 상태 업데이트
    private func updatePermissionStatus(_ settings: UNNotificationSettings) {
        switch settings.authorizationStatus {
        case .authorized:
            permissionStatus = .authorized
        case .denied:
            permissionStatus = .denied
        case .notDetermined:
            permissionStatus = .notDetermined
        case .provisional:
            permissionStatus = .provisional
        case .ephemeral:
            permissionStatus = .ephemeral
        @unknown default:
            permissionStatus = .unknown
        }
        

    }
    
    /// 권한 거부 시 알림 표시
    private func showPermissionDeniedAlert() {
        permissionAlertMessage = "알림 권한이 거부되었습니다. 설정에서 알림을 허용해주세요."
        shouldShowPermissionAlert = true
    }
    
    /// 권한 요청 오류 시 알림 표시
    private func showPermissionErrorAlert(_ error: String) {
        permissionAlertMessage = "알림 권한 요청 중 오류가 발생했습니다: \(error)"
        shouldShowPermissionAlert = true
    }
    
    /// 설정 앱으로 이동
    func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    /// 권한이 필요한지 확인
    var needsPermissionRequest: Bool {
        return permissionStatus == .notDetermined
    }
    
    /// 권한이 거부되었는지 확인
    var isPermissionDenied: Bool {
        return permissionStatus == .denied
    }
    
    /// 권한이 허용되었는지 확인
    var isPermissionGranted: Bool {
        return permissionStatus == .authorized || permissionStatus == .provisional
    }
} 
