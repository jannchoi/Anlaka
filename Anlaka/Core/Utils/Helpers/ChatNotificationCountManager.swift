import Foundation
import UIKit

/// 채팅방별 알림 카운트를 관리하는 매니저
final class ChatNotificationCountManager: ObservableObject {
    static let shared = ChatNotificationCountManager()
    
    @Published private(set) var notificationCounts: [String: Int] = [:]
    
    private let userDefaults = UserDefaults.standard
    private let notificationCountsKey = "ChatNotificationCounts"
    
    private init() {
        loadNotificationCounts()
    }
    
    /// 특정 채팅방의 알림 카운트 증가
    func incrementCount(for roomId: String) {
        let currentCount = notificationCounts[roomId] ?? 0
        notificationCounts[roomId] = currentCount + 1
        saveNotificationCounts()
        
        print("😡 채팅방 \(roomId) 알림 카운트 증가: \(currentCount) → \(currentCount + 1)")
    }
    
    /// 특정 채팅방의 알림 카운트 초기화 (채팅방 진입 시)
    func resetCount(for roomId: String) {
        if notificationCounts[roomId] != nil {
            notificationCounts[roomId] = 0
            saveNotificationCounts()
            
            print("📱 채팅방 \(roomId) 알림 카운트 초기화")
        }
    }
    
    /// 특정 채팅방의 알림 카운트 조회
    func getCount(for roomId: String) -> Int {
        return notificationCounts[roomId] ?? 0
    }
    
    /// 모든 채팅방의 알림 카운트 초기화
    func resetAllCounts() {
        notificationCounts.removeAll()
        saveNotificationCounts()
        print("📱 모든 채팅방 알림 카운트 초기화")
    }
    
    /// 특정 채팅방의 알림 카운트 제거 (채팅방 삭제 시)
    func removeCount(for roomId: String) {
        notificationCounts.removeValue(forKey: roomId)
        saveNotificationCounts()
        print("📱 채팅방 \(roomId) 알림 카운트 제거")
    }
    
    /// 전체 알림 카운트 합계
    var totalCount: Int {
        return notificationCounts.values.reduce(0, +)
    }
    
    /// 배지 상태 디버깅
    func debugBadgeStatus() {
        print("📱 === 배지 상태 디버깅 ===")
        print("📱 계산된 총 카운트: \(totalCount)")
        print("📱 채팅방별 카운트:")
        for (roomId, count) in notificationCounts {
            print("   - \(roomId): \(count)")
        }
        print("📱 =========================")
    }
    
    /// 강제로 배지 업데이트 (iOS가 자동 처리하므로 로그만 출력)
    func forceUpdateBadge() {
        print("📱 내부 알림 카운트: \(totalCount) (iOS가 배지 자동 처리)")
    }
    
    // MARK: - Private Methods
    
    private func saveNotificationCounts() {
        if let data = try? JSONEncoder().encode(notificationCounts) {
            userDefaults.set(data, forKey: notificationCountsKey)
        }
    }
    
    private func loadNotificationCounts() {
        if let data = userDefaults.data(forKey: notificationCountsKey),
           let counts = try? JSONDecoder().decode([String: Int].self, from: data) {
            notificationCounts = counts
        }
    }
} 
