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
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var di = DIContainer(networkRepository: NetworkRepositoryImp())
    
    init() {
        KakaoSDK.initSDK(appKey: Environment.kakaoNativeKey)
        SDKInitializer.InitSDK(appKey: Environment.kakaoNativeKey)
    }
    
    var body: some Scene {
        WindowGroup {
            LoginView(di: di)
                .onOpenURL(perform: { url in
                                if (AuthApi.isKakaoTalkLoginUrl(url)) {
                                    AuthController.handleOpenUrl(url: url)
                                }
            })
        }
    }
}
