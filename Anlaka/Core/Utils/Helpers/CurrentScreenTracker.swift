import Foundation
import SwiftUI

/// 현재 화면 상태를 추적하는 싱글톤 클래스
@MainActor
final class CurrentScreenTracker: ObservableObject {
    static let shared = CurrentScreenTracker()
    
    @Published var currentScreen: ScreenType = .home  // 기본값을 home으로 변경
    @Published var currentChatRoomId: String? = nil
    
    private init() {}
    
    /// 화면 타입 열거형
    enum ScreenType {
        case home
        case community
        case chat
        case estateDetail
        case posting
        case profile
        case settings
    }
    
    /// 현재 화면을 설정
    func setCurrentScreen(_ screen: ScreenType, chatRoomId: String? = nil) {
        let previousScreen = currentScreen
        let previousChatRoomId = currentChatRoomId
        
        currentScreen = screen
        currentChatRoomId = chatRoomId
    }
    
    /// 현재 채팅방에 있는지 확인
    func isInChatRoom(roomId: String) -> Bool {
        return currentScreen == .chat && currentChatRoomId == roomId
    }
    
    /// 채팅 화면인지 확인
    func isInChatScreen() -> Bool {
        return currentScreen == .chat
    }
    
    /// 특정 채팅방에 있는지 확인
    func isInSpecificChatRoom(roomId: String) -> Bool {
        return isInChatRoom(roomId: roomId)
    }
    
    /// 화면 상태 초기화 (앱 시작 시에만 사용)
    func reset() {
        currentScreen = .home
        currentChatRoomId = nil
    }
} 