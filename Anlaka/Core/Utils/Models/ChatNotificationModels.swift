//
//  ChatNotificationModels.swift
//  Anlaka
//
//  Created by 최정안 on 5/13/25.
//

import Foundation
import SwiftUI

// MARK: - 채팅 알림 데이터 모델
struct ChatNotificationData {
    let roomId: String
    let senderId: String
    let senderName: String
    let message: String
    let timestamp: Date
    let notificationType: ChatNotificationType
}

enum ChatNotificationType {
    case newMessage
    case fileUpload
    case systemMessage
}

// MARK: - 라우팅 큐 아이템
struct RoutingQueueItem {
    let id = UUID()
    let roomId: String
    let timestamp: Date
    let source: RoutingSource
    
    enum RoutingSource {
        case pushNotification
        case deepLink
        case inAppAction
    }
}

// MARK: - 라우팅 상태 관리자
@MainActor
class RoutingStateManager: ObservableObject {
    static let shared = RoutingStateManager()
    
    @Published var currentTab: Tab = .home
    @Published var pendingNavigation: NavigationDestination?
    @Published var isNavigating = false
    
    enum Tab: Int, CaseIterable {
        case home = 0, community = 1, reserved = 2, myPage = 3
    }
    
    enum NavigationDestination: Equatable, CustomStringConvertible {
        case chatRoom(roomId: String)
        case estateDetail(estateId: String)
        case postDetail(postId: String)
        case profile
        case settings
        
        var description: String {
            switch self {
            case .chatRoom(let roomId):
                return "chatRoom(\(roomId))"
            case .estateDetail(let estateId):
                return "estateDetail(\(estateId))"
            case .postDetail(let postId):
                return "postDetail(\(postId))"
            case .profile:
                return "profile"
            case .settings:
                return "settings"
            }
        }
        
        static func == (lhs: NavigationDestination, rhs: NavigationDestination) -> Bool {
            switch (lhs, rhs) {
            case (.chatRoom(let lRoomId), .chatRoom(let rRoomId)):
                return lRoomId == rRoomId
            case (.estateDetail(let lEstateId), .estateDetail(let rEstateId)):
                return lEstateId == rEstateId
            case (.postDetail(let lPostId), .postDetail(let rPostId)):
                return lPostId == rPostId
            case (.profile, .profile):
                return true
            case (.settings, .settings):
                return true
            default:
                return false
            }
        }
    }
    
    private init() {}
    
    /// 라우팅 큐 아이템 처리
    func processRoutingQueue(_ item: RoutingQueueItem) {
        print("📱 라우팅 큐 아이템 처리: \(item.roomId)")
        
        // MyPage 탭으로 이동 (채팅방 목록이 있는 탭)
        currentTab = .myPage
        print("📱 현재 탭을 MyPage로 변경: \(currentTab)")
        
        // 채팅방으로 이동할 네비게이션 설정
        pendingNavigation = .chatRoom(roomId: item.roomId)
        isNavigating = true
        print("📱 네비게이션 설정: \(pendingNavigation?.description ?? "nil")")
    }
    
    /// 네비게이션 완료 후 상태 초기화
    func completeNavigation() {
        pendingNavigation = nil
        isNavigating = false
    }
    
    /// 특정 탭으로 이동
    func navigateToTab(_ tab: Tab) {
        currentTab = tab
    }
    
    /// 채팅방으로 직접 이동
    func navigateToChatRoom(_ roomId: String) {
        currentTab = .myPage
        pendingNavigation = .chatRoom(roomId: roomId)
        isNavigating = true
    }
}

// MARK: - 알림 라우팅 큐 관리자
@MainActor
class NotificationRoutingQueue: ObservableObject {
    static let shared = NotificationRoutingQueue()
    
    @Published var isLoggedIn: Bool = false
    @Published var routingQueue: [RoutingQueueItem] = []
    
    private let routingStateManager = RoutingStateManager.shared
    
    private init() {}
    
    func enqueueChatRoom(_ roomId: String, source: RoutingQueueItem.RoutingSource = .pushNotification) {
        print("📱 라우팅 큐에 채팅방 등록: \(roomId)")
        print("📱 현재 로그인 상태: \(isLoggedIn)")
        
        let queueItem = RoutingQueueItem(
            roomId: roomId,
            timestamp: Date(),
            source: source
        )
        
        // 중복 제거 (같은 채팅방이 이미 큐에 있으면 제거)
        routingQueue.removeAll { $0.roomId == roomId }
        
        // 새 아이템 추가
        routingQueue.append(queueItem)
        
        // 로그인된 상태라면 즉시 처리
        if isLoggedIn {
            print("📱 로그인 상태 - 즉시 큐 처리 시작")
            processNextQueueItem()
        } else {
            print("📱 비로그인 상태 - 큐에 저장 후 대기")
        }
    }
    
    func dequeueChatRoom() -> String? {
        guard let item = routingQueue.first else { return nil }
        
        let roomId = item.roomId
        routingQueue.removeFirst()
        print("📱 라우팅 큐에서 채팅방 제거: \(roomId)")
        return roomId
    }
    
    func clearQueue() {
        routingQueue.removeAll()
        print("📱 라우팅 큐 초기화")
    }
    
    /// 다음 큐 아이템 처리
    func processNextQueueItem() {
        guard let item = routingQueue.first else { 
            print("📱 처리할 큐 아이템이 없음")
            return 
        }
        
        print("📱 다음 큐 아이템 처리: \(item.roomId)")
        
        // 채팅방 진입 시 배지 카운트 차감
        deductBadgeCountForChatRoom(item.roomId)
        
        print("📱 RoutingStateManager에 라우팅 요청 전송")
        routingStateManager.processRoutingQueue(item)
        
        // 처리된 아이템 제거
        routingQueue.removeFirst()
        print("📱 큐 아이템 처리 완료 및 제거")
    }
    
    /// 채팅방 진입 시 알림 제거 (iOS가 배지를 자동으로 처리)
    private func deductBadgeCountForChatRoom(_ roomId: String) {
        print("📱 채팅방 \(roomId) 진입 - 알림 제거")
        
        // 1. 해당 채팅방의 앱 내 알림 제거
        InAppNotificationManager.shared.removeChatNotifications(forRoomId: roomId)
        
        // 2. 시스템 알림 센터에서 해당 채팅방 알림 제거
        removeSystemNotificationsForChatRoom(roomId)
        
        print("📱 채팅방 진입 시 알림 제거 완료 (iOS가 배지 자동 처리)")
    }
    
    /// 시스템 알림 센터에서 특정 채팅방의 알림 제거
    private func removeSystemNotificationsForChatRoom(_ roomId: String) {
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            let chatNotifications = notifications.filter { notification in
                let userInfo = notification.request.content.userInfo
                let stringUserInfo = userInfo.compactMapKeys { $0 as? String }
                return stringUserInfo["room_id"] as? String == roomId
            }
            
            let notificationIds = chatNotifications.map { $0.request.identifier }
            
            if !notificationIds.isEmpty {
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: notificationIds)
                print("📱 시스템 알림 센터에서 채팅방 \(roomId) 알림 \(notificationIds.count)개 제거")
            }
        }
    }
    
    /// 로그인 상태 변경 시 대기 중인 큐 처리
    func handleLoginStateChange(_ isLoggedIn: Bool) {
        print("📱 NotificationRoutingQueue 로그인 상태 변경: \(self.isLoggedIn) → \(isLoggedIn)")
        self.isLoggedIn = isLoggedIn
        
        if isLoggedIn {
            print("📱 로그인 완료 - 대기 중인 큐 처리 시작 (큐 개수: \(routingQueue.count))")
            // 로그인 완료 시 대기 중인 큐 처리
            while !routingQueue.isEmpty {
                processNextQueueItem()
            }
        } else {
            print("📱 로그아웃 - 큐 처리 중단")
        }
    }
    
    /// 특정 채팅방 관련 큐 아이템 제거
    func removeQueueItems(forRoomId roomId: String) {
        routingQueue.removeAll { $0.roomId == roomId }
        print("📱 채팅방 \(roomId) 관련 큐 아이템 제거")
    }
    
    /// 현재 큐 상태 출력 (디버깅용)
    func printQueueStatus() {
        print("📱 현재 라우팅 큐 상태:")
        print("   - 로그인 상태: \(isLoggedIn)")
        print("   - 큐 아이템 개수: \(routingQueue.count)")
        for (index, item) in routingQueue.enumerated() {
            print("   - [\(index)] \(item.roomId) (소스: \(item.source))")
        }
    }
} 