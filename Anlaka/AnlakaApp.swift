//
//  AnlakaApp.swift
//  Anlaka
//
//  Created by 최정안 on 5/10/25.
//

import SwiftUI
import KakaoSDKCommon
import KakaoSDKAuth
import KakaoMapsSDK

@main
struct AnlakaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var di = try! DIContainer.create()
    @AppStorage(TextResource.Global.isLoggedIn.text) private var isLoggedIn: Bool = false

    
    init() {
        KakaoSDK.initSDK(appKey: AppConfig.kakaoNativeKey)
        SDKInitializer.InitSDK(appKey: AppConfig.kakaoNativeKey)
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
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isLoggedIn {
                    MyTabView(di: di)
                } else {
                    LoginView(di: di)
                }
            }
            .onOpenURL(perform: { url in
                if AuthApi.isKakaoTalkLoginUrl(url) {
                    AuthController.handleOpenUrl(url: url)
                }
            })
            .task {
                await setupCacheCleanup() // 비동기 작업을 onAppear 또는 task 수정자에서 호출
            }
        }
    }
}
