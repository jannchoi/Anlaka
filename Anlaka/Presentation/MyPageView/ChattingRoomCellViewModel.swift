//
//  ChattingRoomCellViewModel.swift
//  Anlaka
//
//  Created by 최정안 on 7/25/25.
//

import Foundation
import SwiftUI

// MARK: - ChattingRoomCellViewModel
@MainActor
final class ChattingRoomCellViewModel: ObservableObject {
    @Published var lastMessage: String = ""
    @Published var notificationCount: Int = 0
    @Published var lastMessageTime: String = ""
    
    private let roomId: String
    private let notificationCountManager: ChatNotificationCountManager
    private let temporaryMessageManager: TemporaryLastMessageManager
    
    init(roomId: String, initialRoom: ChatRoomEntity) {
        self.roomId = roomId
        self.notificationCountManager = ChatNotificationCountManager.shared
        self.temporaryMessageManager = TemporaryLastMessageManager.shared
        
        // 초기 데이터 설정
        updateLastMessage(from: initialRoom)
        updateNotificationCount()
        
        // 알림 업데이트 구독
        NotificationCenter.default.addObserver(
            forName: .chatNotificationUpdate,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateNotificationCount()
            self?.updateLastMessageFromTemporary()
        }
        
        // 포그라운드 진입 시 업데이트 구독
        NotificationCenter.default.addObserver(
            forName: .appDidEnterForeground,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateNotificationCount()
            self?.updateLastMessageFromTemporary()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func updateLastMessage(from room: ChatRoomEntity) {
        lastMessage = room.lastChat?.content ?? ""
        lastMessageTime = room.lastChat?.updatedAt ?? ""
    }
    
    private func updateLastMessageFromTemporary() {
        if let tempMessage = temporaryMessageManager.getTemporaryLastMessage(for: roomId) {
            lastMessage = tempMessage.content
            lastMessageTime = PresentationMapper.formatDateToISO8601(tempMessage.timestamp)
        }
    }
    
    private func updateNotificationCount() {
        notificationCount = notificationCountManager.getCount(for: roomId)
    }
} 