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
    
    enum NavigationDestination: Equatable {
        case chatRoom(roomId: String)
        case estateDetail(estateId: String)
        case postDetail(postId: String)
        case profile
        case settings
        
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
        
        // 채팅방으로 이동할 네비게이션 설정
        pendingNavigation = .chatRoom(roomId: item.roomId)
        isNavigating = true
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
    
    @Published var pendingChatRoomId: String?
    @Published var isLoggedIn: Bool = false
    @Published var routingQueue: [RoutingQueueItem] = []
    
    private let routingStateManager = RoutingStateManager.shared
    
    private init() {}
    
    func enqueueChatRoom(_ roomId: String, source: RoutingQueueItem.RoutingSource = .pushNotification) {
        print("📱 라우팅 큐에 채팅방 등록: \(roomId)")
        
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
            processNextQueueItem()
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
        pendingChatRoomId = nil
        print("📱 라우팅 큐 초기화")
    }
    
    /// 다음 큐 아이템 처리
    func processNextQueueItem() {
        guard let item = routingQueue.first else { return }
        
        print("📱 다음 큐 아이템 처리: \(item.roomId)")
        
        // 채팅방 진입 시 배지 카운트 차감
        deductBadgeCountForChatRoom(item.roomId)
        
        routingStateManager.processRoutingQueue(item)
        
        // 처리된 아이템 제거
        routingQueue.removeFirst()
    }
    
    /// 채팅방 진입 시 배지 카운트 차감 및 알림 제거
    private func deductBadgeCountForChatRoom(_ roomId: String) {
        print("📱 채팅방 \(roomId) 진입 - 배지 카운트 차감 및 알림 제거")
        
        // 1. 해당 채팅방의 앱 내 알림 제거
        InAppNotificationManager.shared.removeChatNotifications(forRoomId: roomId)
        
        // 2. 현재 앱 배지 카운트 가져오기
        let currentBadgeCount = UIApplication.shared.applicationIconBadgeNumber
        
        // 3. 해당 채팅방의 알림 개수만큼 차감 (최소 0)
        let newBadgeCount = max(0, currentBadgeCount - 1)
        
        // 4. 앱 배지 카운트 업데이트
        UIApplication.shared.applicationIconBadgeNumber = newBadgeCount
        
        // 5. UserDefaults에도 저장
        UserDefaultsManager.shared.set(newBadgeCount, forKey: .badgeCount)
        
        print("📱 배지 카운트 업데이트: \(currentBadgeCount) → \(newBadgeCount)")
    }
    
    /// 로그인 상태 변경 시 대기 중인 큐 처리
    func handleLoginStateChange(_ isLoggedIn: Bool) {
        self.isLoggedIn = isLoggedIn
        
        if isLoggedIn {
            // 로그인 완료 시 대기 중인 큐 처리
            while !routingQueue.isEmpty {
                processNextQueueItem()
            }
        }
    }
    
    /// 특정 채팅방 관련 큐 아이템 제거
    func removeQueueItems(forRoomId roomId: String) {
        routingQueue.removeAll { $0.roomId == roomId }
        print("📱 채팅방 \(roomId) 관련 큐 아이템 제거")
    }
} 