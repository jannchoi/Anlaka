//
//  ContentView.swift
//  Anlaka
//
//  Created by 최정안 on 5/10/25.
//

import SwiftUI
import KakaoSDKCommon
import KakaoSDKAuth
import KakaoMapsSDK

struct ContentView: View {
    @StateObject private var di = try! DIContainer.create()
    @AppStorage(TextResource.Global.isLoggedIn.text) private var isLoggedIn: Bool = false
    // NotificationRoutingQueue는 딥링크 시스템으로 대체되어 제거됨
    @StateObject private var permissionManager = NotificationPermissionManager.shared
    
    var body: some View {
        // 로그인 상태에 따라 직접 뷰 전환
        Group {
            if isLoggedIn {
                MyTabView(di: di)
            } else {
                LoginView(di: di)
            }
        }
        .customNotificationBanner()
        .onReceive(NotificationCenter.default.publisher(for: .appDidEnterForeground)) { _ in
            // 앱이 포그라운드로 진입할 때 대기 중인 딥링크 처리
            if isLoggedIn {
                handlePendingChatRoom()
            }
        }
        .onOpenURL(perform: { url in
            print("📱 딥링크 URL 수신: \(url)")
            
            // 카카오 로그인 URL 처리
            if AuthApi.isKakaoTalkLoginUrl(url) {
                AuthController.handleOpenUrl(url: url)
                return
            }
            
            // 앱 딥링크 처리
            DeepLinkProcessor.shared.processDeepLink(url)
        })
        .task {
            await setupCacheCleanup()
            print("📱 앱 시작 시 로그인 상태 설정: \(isLoggedIn)")
            
            // 앱 시작 시 대기 중인 딥링크 처리
            if isLoggedIn {
                handlePendingChatRoom()
            }
        }
        .onChange(of: isLoggedIn) { newValue in
            print("🔐 ContentView에서 isLoggedIn 변경 감지: \(newValue)")
            
            // 로그인 상태가 변경될 때 대기 중인 채팅방 처리
            if newValue {
                handlePendingChatRoom()
            } else {
                // 로그아웃 시 알림 관련 데이터 초기화
                ChatNotificationCountManager.shared.clearAllCounts()
                TemporaryLastMessageManager.shared.clearAllTemporaryMessages()
                CustomNotificationManager.shared.clearAllNotifications()
            }
            
            print("📱 로그인 상태 변경 감지: \(newValue)")
            
            // SwiftUI가 자동으로 화면 전환을 처리하므로 별도 작업 불필요
            print("🔄 SwiftUI가 자동으로 화면 전환 처리")
        }
        .alert("알림 권한", isPresented: $permissionManager.shouldShowPermissionAlert) {
            Button("설정으로 이동") {
                permissionManager.openSettings()
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text(permissionManager.permissionAlertMessage)
        }
    }
    
    private func setupCacheCleanup() async {
        do {
            // 디스크 캐시 만료된 파일들 정리 (비동기) - 타임아웃 설정
            try await withTimeout(seconds: 5.0) {
                await SafeDiskCacheManager.shared.clearExpiredCache()
            }
            
            // 캐시 통계 로깅 (비동기) - 타임아웃 설정
            let stats = try await withTimeout(seconds: 3.0) {
                return await SafeImageCache.shared.getCacheStatistics()
            }
            //print("📊 캐시 통계 - 총 비용: \(stats.totalCost / 1024 / 1024)MB, 이미지 개수: \(stats.count)")
            
        } catch {
            print("⚠️ 캐시 초기화 중 오류 발생: \(error.localizedDescription)")
        }
    }
    
    private func handlePendingChatRoom() {
        // 대기 중인 채팅방 ID가 있는지 확인
        if let pendingChatRoomId = UserDefaultsManager.shared.getString(forKey: .pendingChatRoomId) {
            // 새로운 딥링크 시스템 사용
            if let deepLinkURL = DeepLinkScheme.createURL(type: .chat, id: pendingChatRoomId, source: .pushNotification) {
                DeepLinkProcessor.shared.processDeepLink(deepLinkURL)
            }
            
            UserDefaultsManager.shared.remove(forKey: .pendingChatRoomId)
        }
    }
}

// 타임아웃을 포함한 비동기 작업 래퍼
private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    return try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            return try await operation()
        }
        
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw CancellationError()
        }
        
        for try await result in group {
            return result
        }
        
        throw CancellationError()
    }
}

