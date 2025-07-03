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
    @AppStorage(TextResource.Global.isLoggedIn.text) private var isLoggedIn: Bool = false
    
    
    init() {
        KakaoSDK.initSDK(appKey: AppConfig.kakaoNativeKey)
        SDKInitializer.InitSDK(appKey: AppConfig.kakaoNativeKey)
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
                if (AuthApi.isKakaoTalkLoginUrl(url)) {
                    AuthController.handleOpenUrl(url: url)
                }
            })
        }
    }
}
