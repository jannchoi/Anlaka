//
//  InAppNotificationBanner.swift
//  Anlaka
//
//  Created by 최정안 on 5/13/25.
//

import SwiftUI

// MARK: - 알림 상태 열거형
enum NotificationDisplayState {
    case bell(NotificationData)
    case banner(NotificationData)
    case hidden
}

// MARK: - 알림 데이터 모델
struct NotificationData {
    let id = UUID()
    let roomId: String
    let senderName: String
    let message: String
    let timestamp: Date
    let unreadCount: Int
    let groupedMessages: [String] // 그룹화된 메시지들
    
    init(roomId: String, senderName: String, message: String, unreadCount: Int = 1, groupedMessages: [String] = []) {
        self.roomId = roomId
        self.senderName = senderName
        self.message = message
        self.timestamp = Date()
        self.unreadCount = unreadCount
        self.groupedMessages = groupedMessages.isEmpty ? [message] : groupedMessages
    }
}

// MARK: - 흔들리는 벨 뷰
struct ShakingBellView: View {
    @State private var isShaking = false
    @State private var isVisible = false
    let notificationData: NotificationData
    let onTap: () -> Void
    let onSwipe: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // 벨 아이콘
            Image(systemName: "bell")
                .font(.title2)
                .foregroundColor(.TomatoRed)
                .rotationEffect(Angle(degrees: isShaking ? -10 : 10))
                .animation(
                    .easeInOut(duration: 0.1)
                    .repeatCount(6, autoreverses: true),
                    value: isShaking
                )
            
            // 알림 개수 배지
            if notificationData.unreadCount > 1 {
                Text("\(notificationData.unreadCount)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 18, height: 18)
                    .background(Color.TomatoRed)
                    .clipShape(Circle())
    }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        .offset(x: isVisible ? 0 : 100)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                isVisible = true
            }
            isShaking = true
        }
        .onTapGesture {
            onTap()
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width < -50 {
                        onSwipe()
                    }
                }
        )
    }
}

// MARK: - 커스텀 배너 뷰
struct CustomNotificationBanner: View {
    @State private var isVisible = false
    let notificationData: NotificationData
    let onTap: () -> Void
    let onSwipe: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 아이콘
            Image(systemName: "message.fill")
                .font(.title2)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 4) {
                // 제목
                Text(notificationData.senderName)
                    .font(.pretendardSubheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                // 메시지
                if notificationData.unreadCount > 1 {
                    Text("새로운 메시지 \(notificationData.unreadCount)개")
                        .font(.pretendardCaption)
                        .foregroundColor(.white.opacity(0.9))
                } else {
                    Text(notificationData.message)
                    .font(.pretendardCaption)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
                }
            }
            
            Spacer()
            
            // 닫기 버튼
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.DeepForest)
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
            onTap()
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height < -50 {
                        onSwipe()
                    }
                }
        )
    }
}

// MARK: - 커스텀 알림 관리자
@MainActor
class CustomNotificationManager: ObservableObject {
    static let shared = CustomNotificationManager()
    
    @Published var displayState: NotificationDisplayState = .hidden
    @Published var currentNotification: NotificationData?
    
    private var bellTimer: Timer?
    private var bannerTimer: Timer?
    private var groupedNotifications: [String: [NotificationData]] = [:] // roomId별 그룹화
    private let bellAutoDismissInterval: TimeInterval = 3.0
    private let bannerAutoDismissInterval: TimeInterval = 5.0
    private let groupingTimeWindow: TimeInterval = 3.0 // 3초 내 같은 방 알림 그룹화
    
    private init() {}
    
    /// 새로운 알림 처리
    func handleNewNotification(roomId: String, senderName: String, message: String) {
        // 현재 채팅방에 있는지 확인
        if isInCurrentChatRoom(roomId: roomId) {
            return
        }
        
        // 기존 알림이 있다면 그룹화 시도
        if let existing = currentNotification, existing.roomId == roomId {
            let timeDiff = Date().timeIntervalSince(existing.timestamp)
            if timeDiff < groupingTimeWindow {
                // 그룹화
                let updatedData = NotificationData(
                    roomId: roomId,
                    senderName: senderName,
                    message: message,
                    unreadCount: existing.unreadCount + 1,
                    groupedMessages: existing.groupedMessages + [message]
                )
                updateNotification(updatedData)
                return
            }
        }
        
        // 새로운 알림 생성
        let newNotification = NotificationData(
            roomId: roomId,
            senderName: senderName,
            message: message
        )
        updateNotification(newNotification)
    }
    
    /// 알림 상태 업데이트
    private func updateNotification(_ notification: NotificationData) {
        currentNotification = notification
        
        switch displayState {
        case .hidden:
            // 벨 상태로 시작
            displayState = .bell(notification)
            startBellTimer()
            
        case .bell:
            // 벨 상태에서 새 알림 - 벨 업데이트
            displayState = .bell(notification)
            resetBellTimer()
            
        case .banner:
            // 배너 상태에서 새 알림 - 배너 업데이트
            displayState = .banner(notification)
            resetBannerTimer()
        }
    }
    
    /// 벨 탭 처리
    func handleBellTap() {
        guard case .bell(let notification) = displayState else { return }
        
        // 배너 상태로 전환
        displayState = .banner(notification)
        stopBellTimer()
        startBannerTimer()
    }
    
    /// 배너 탭 처리
    func handleBannerTap() {
        guard case .banner(let notification) = displayState else { return }
        
        // 딥링크 시스템을 통해 채팅방으로 이동
        if let deepLinkURL = DeepLinkScheme.createURL(type: .chat, id: notification.roomId, source: .pushNotification) {
            DeepLinkProcessor.shared.processDeepLink(deepLinkURL)
        }
        
        clearAllNotifications()
    }
    
    /// 벨 스와이프 처리
    func handleBellSwipe() {
        displayState = .hidden
        stopBellTimer()
        currentNotification = nil
    }
    
    /// 배너 스와이프 처리
    func handleBannerSwipe() {
        displayState = .hidden
        stopBannerTimer()
        currentNotification = nil
    }
    
    /// 배너 닫기 처리
    func handleBannerClose() {
        displayState = .hidden
        stopBannerTimer()
        currentNotification = nil
    }
    
    /// 모든 알림 제거
    func clearAllNotifications() {
        displayState = .hidden
        stopBellTimer()
        stopBannerTimer()
        currentNotification = nil
        groupedNotifications.removeAll()
    }
    
    /// 특정 채팅방 알림 제거
    func clearNotificationsForRoom(_ roomId: String) {
        if case .banner(let notification) = displayState, notification.roomId == roomId {
            clearAllNotifications()
        } else if case .bell(let notification) = displayState, notification.roomId == roomId {
            clearAllNotifications()
        }
        groupedNotifications.removeValue(forKey: roomId)
    }
    
    // MARK: - 타이머 관리
    private func startBellTimer() {
        bellTimer?.invalidate()
        bellTimer = Timer.scheduledTimer(withTimeInterval: bellAutoDismissInterval, repeats: false) { _ in
            DispatchQueue.main.async {
                if case .bell = self.displayState {
                    self.displayState = .hidden
                    self.currentNotification = nil
                }
            }
        }
    }
    
    private func resetBellTimer() {
        startBellTimer()
    }
    
    private func stopBellTimer() {
        bellTimer?.invalidate()
        bellTimer = nil
    }
    
    private func startBannerTimer() {
        bannerTimer?.invalidate()
        bannerTimer = Timer.scheduledTimer(withTimeInterval: bannerAutoDismissInterval, repeats: false) { _ in
            DispatchQueue.main.async {
                if case .banner = self.displayState {
                    self.displayState = .hidden
                    self.currentNotification = nil
                }
            }
        }
    }
    
    private func resetBannerTimer() {
        startBannerTimer()
    }
    
    private func stopBannerTimer() {
        bannerTimer?.invalidate()
        bannerTimer = nil
    }
    
    // MARK: - 헬퍼 메서드
    private var currentChatRoomId: String?
    
    /// 현재 채팅방 ID 설정
    func setCurrentChatRoom(_ roomId: String?) {
        currentChatRoomId = roomId
    }
    
    private func isInCurrentChatRoom(roomId: String) -> Bool {
        guard let currentRoomId = currentChatRoomId else { return false }
        return currentRoomId == roomId
    }
}

// MARK: - 커스텀 알림 컨테이너
struct CustomNotificationContainer: View {
    @StateObject private var notificationManager = CustomNotificationManager.shared
    
    var body: some View {
        ZStack {
            Color.clear
            
            VStack {
                switch notificationManager.displayState {
                case .bell(let notification):
                    ShakingBellView(
                        notificationData: notification,
                        onTap: {
                            notificationManager.handleBellTap()
                        },
                        onSwipe: {
                            notificationManager.handleBellSwipe()
                        }
                    )
                    .padding(.top, 60)
                    .padding(.trailing, 12)
                    
                case .banner(let notification):
                    CustomNotificationBanner(
                        notificationData: notification,
                        onTap: {
                            notificationManager.handleBannerTap()
                        },
                        onSwipe: {
                            notificationManager.handleBannerSwipe()
                        },
                        onClose: {
                            notificationManager.handleBannerClose()
                        }
                    )
                    .padding(.top, 60)
                    .padding(.horizontal, 16)
                    
                case .hidden:
                    EmptyView()
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - View 확장
extension View {
    func customNotificationBanner() -> some View {
        self.overlay(
            CustomNotificationContainer()
        )
    }
} 
