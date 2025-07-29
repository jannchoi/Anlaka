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

// MARK: - 라우팅 상태 관리자
@MainActor
class RoutingStateManager: ObservableObject {
    static let shared = RoutingStateManager()
    
    @Published var currentTab: Tab = .home
    @Published var pendingNavigation: NavigationDestination?
    @Published var isNavigating = false
    @Published var isNavigationInProgress = false
    
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
    
    /// 라우팅 큐 아이템 처리 (기존 시스템 - 딥링크로 대체됨)
    func processRoutingQueue(_ item: Any) {
        // 이 메서드는 딥링크 시스템으로 대체되어 더 이상 사용되지 않습니다.
    }
    
    /// 네비게이션 완료 후 상태 초기화
    func completeNavigation() {
        // 이미 완료된 상태라면 중복 호출 방지
        if !isNavigationInProgress {
            return
        }
        
        pendingNavigation = nil
        isNavigating = false
        isNavigationInProgress = false
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
        isNavigationInProgress = true
    }
}
