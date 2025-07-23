//
//  InAppNotificationBanner.swift
//  Anlaka
//
//  Created by 최정안 on 5/13/25.
//

import SwiftUI

// MARK: - 앱 내 알림 배너 모델
struct InAppNotification {
    let id = UUID()
    let title: String
    let message: String
    let timestamp: Date
    let type: InAppNotificationType
    let action: (() -> Void)?
    let roomId: String? // 채팅방 ID 추가
    
    enum InAppNotificationType {
        case chat
        case system
        case warning
        case success
    }
}

// MARK: - 앱 내 알림 배너 관리자
@MainActor
class InAppNotificationManager: ObservableObject {
    static let shared = InAppNotificationManager()
    
    @Published var notifications: [InAppNotification] = []
    @Published var isPermissionDenied = false
    
    private let maxNotifications = 3
    private let autoDismissInterval: TimeInterval = 5.0
    
    private init() {}
    
    /// 새로운 알림 추가
    func addNotification(_ notification: InAppNotification) {
        print("📱 새로운 인앱 알림 추가: \(notification.title) - \(notification.message)")
        
        // 최대 개수 제한 (최대 3개 배너 표시)
        if notifications.count >= maxNotifications {
            let removedNotification = notifications.removeFirst()
            print("📱 최대 개수 초과로 가장 오래된 알림 제거: \(removedNotification.title)")
        }
        
        notifications.append(notification)
        print("📱 현재 알림 개수: \(notifications.count)/\(maxNotifications)")
        
        // 자동 제거 타이머 설정
        DispatchQueue.main.asyncAfter(deadline: .now() + autoDismissInterval) {
            self.removeNotification(withId: notification.id)
        }
    }
    
    /// 채팅 알림 추가
    func addChatNotification(roomId: String, senderName: String, message: String, action: (() -> Void)? = nil) {
        let notification = InAppNotification(
            title: senderName,
            message: message,
            timestamp: Date(),
            type: .chat,
            action: action,
            roomId: roomId // 채팅방 ID 저장
        )
        addNotification(notification)
    }
    
    /// 시스템 알림 추가
    func addSystemNotification(title: String, message: String) {
        let notification = InAppNotification(
            title: title,
            message: message,
            timestamp: Date(),
            type: .system,
            action: nil,
            roomId: nil // 시스템 알림은 roomId 없음
        )
        addNotification(notification)
    }
    
    /// 알림 제거
    func removeNotification(withId id: UUID) {
        notifications.removeAll { $0.id == id }
    }
    
    /// 모든 알림 제거
    func clearAllNotifications() {
        notifications.removeAll()
    }
    
    /// 특정 채팅방 관련 알림 제거
    func removeChatNotifications(forRoomId roomId: String) {
        print("📱 채팅방 \(roomId) 관련 알림 제거")
        
        // 해당 채팅방의 모든 알림 제거
        let removedCount = notifications.removeAll { notification in
            notification.type == .chat && notification.roomId == roomId
        }
        
        print("📱 제거된 알림 개수: \(removedCount)")
    }
}

// MARK: - 앱 내 알림 배너 뷰
struct InAppNotificationBanner: View {
    let notification: InAppNotification
    let onDismiss: () -> Void
    
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 12) {
            // 아이콘
            notificationIcon
            
            VStack(alignment: .leading, spacing: 4) {
                // 제목
                Text(notification.title)
                    .font(.pretendardSubheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                // 메시지
                Text(notification.message)
                    .font(.pretendardCaption)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
            }
            
            Spacer()
            
            // 닫기 버튼
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(backgroundColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        .offset(y: isVisible ? 0 : -100)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                isVisible = true
            }
        }
        .onTapGesture {
            // 알림 탭 시 액션 실행
            notification.action?()
            onDismiss()
        }
    }
    
    private var notificationIcon: some View {
        Image(systemName: iconName)
            .font(.title2)
            .foregroundColor(.white)
            .frame(width: 24, height: 24)
    }
    
    private var iconName: String {
        switch notification.type {
        case .chat:
            return "message.fill"
        case .system:
            return "bell.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .success:
            return "checkmark.circle.fill"
        }
    }
    
    private var backgroundColor: Color {
        switch notification.type {
        case .chat:
            return Color.DeepForest
        case .system:
            return Color.SteelBlue
        case .warning:
            return Color.TomatoRed
        case .success:
            return Color.OliveMist
        }
    }
}

// MARK: - 앱 내 알림 배너 컨테이너
struct InAppNotificationContainer: View {
    @StateObject private var notificationManager = InAppNotificationManager.shared
    
    var body: some View {
        ZStack {
            // 메인 콘텐츠는 그대로 유지
            Color.clear
            
            // 알림 배너들
            VStack {
                ForEach(notificationManager.notifications, id: \.id) { notification in
                    InAppNotificationBanner(
                        notification: notification,
                        onDismiss: {
                            notificationManager.removeNotification(withId: notification.id)
                        }
                    )
                }
                Spacer()
            }
            .padding(.top, 60) // 상태바 아래 여백
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - View 확장
extension View {
    func inAppNotificationBanner() -> some View {
        self.overlay(
            InAppNotificationContainer()
        )
    }
} 
