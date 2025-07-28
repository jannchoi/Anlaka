import Foundation
import UIKit
import os.log
/// 채팅방별 알림 카운트를 관리하는 매니저
final class ChatNotificationCountManager: ObservableObject {
    static let shared = ChatNotificationCountManager()
    
    @Published private(set) var notificationCounts: [String: Int] = [:]
    
    private let userDefaults: UserDefaults? = {
        let suiteName = "group.com.jann.Anlaka"
        guard !suiteName.isEmpty else {
            print("❌ UserDefaults suiteName이 빈 문자열입니다")
            return nil
        }
        return UserDefaults(suiteName: suiteName)
    }()
    private let notificationCountsKey = "ChatNotificationCounts"
    
    private init() {
        migrateFromStandardUserDefaults()
        loadNotificationCounts()
    }
    
    /// 특정 채팅방의 알림 카운트 증가
    func incrementCount(for roomId: String) {
        let currentCount = notificationCounts[roomId] ?? 0
        notificationCounts[roomId] = currentCount + 1
        saveNotificationCounts()
        
        // 앱 아이콘 배지 업데이트
        updateAppIconBadge()
        
        print("😡 채팅방 \(roomId) 알림 카운트 증가: \(currentCount) → \(currentCount + 1)")
    }
    
    /// 특정 채팅방의 알림 카운트 초기화 (채팅방 진입 시)
    func resetCount(for roomId: String) {
        if notificationCounts[roomId] != nil {
            notificationCounts[roomId] = 0
            saveNotificationCounts()
            
            // 앱 아이콘 배지 업데이트
            updateAppIconBadge()
            
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
    
    /// 모든 채팅방의 알림 카운트 초기화 (clearAllCounts와 동일)
    func clearAllCounts() {
        resetAllCounts()
    }
    
    /// 특정 채팅방의 알림 카운트 제거 (채팅방 삭제 시)
    func removeCount(for roomId: String) {
        notificationCounts.removeValue(forKey: roomId)
        saveNotificationCounts()
        
        // 앱 아이콘 배지 업데이트
        updateAppIconBadge()
        
        // @Published 속성이 변경되었음을 알림
        objectWillChange.send()
        
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
    
    /// 앱 아이콘 배지 업데이트
    private func updateAppIconBadge() {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = self.totalCount
        }
        print("📱 앱 아이콘 배지 업데이트: \(totalCount)")
    }
    
    /// 강제로 배지 업데이트 (iOS가 자동 처리하므로 로그만 출력)
    func forceUpdateBadge() {
        updateAppIconBadge()
    }
    
    /// 테스트용 배지 설정
    func setTestBadge() {
        notificationCounts["test_room"] = 3
        saveNotificationCounts()
        updateAppIconBadge()
        print("📱 테스트 배지 설정: 3")
    }
    
    // MARK: - Private Methods
    
    private func saveNotificationCounts() {
        guard let userDefaults = userDefaults else {
            os_log(.error, "❌ UserDefaults(suiteName: group.com.jann.Anlaka) 초기화 실패")
            return
        }
        if let data = try? JSONEncoder().encode(notificationCounts) {
            userDefaults.set(data, forKey: notificationCountsKey)
            userDefaults.synchronize()
            os_log(.debug, "📱 UserDefaults 저장 완료: %@", "\(notificationCounts)")
        } else {
            os_log(.error, "❌ JSONEncoder 실패")
        }
    }
    
    private func loadNotificationCounts() {
        if let data = userDefaults?.data(forKey: notificationCountsKey),
           let counts = try? JSONDecoder().decode([String: Int].self, from: data) {
            notificationCounts = counts
        }
    }
    
    /// 기존 UserDefaults에서 App Groups로 데이터 마이그레이션
    private func migrateFromStandardUserDefaults() {
        let standardDefaults = UserDefaults.standard
        let oldData = standardDefaults.data(forKey: notificationCountsKey)
        
        if let oldData = oldData,
           let oldCounts = try? JSONDecoder().decode([String: Int].self, from: oldData),
           !oldCounts.isEmpty {
            print("📱 기존 UserDefaults에서 알림 카운트 마이그레이션: \(oldCounts)")
            notificationCounts = oldCounts
            saveNotificationCounts()
            
            // 마이그레이션 후 기존 데이터 삭제
            standardDefaults.removeObject(forKey: notificationCountsKey)
            print("📱 마이그레이션 완료 - 기존 데이터 삭제")
        }
    }
} 
