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

    
    init() {
        KakaoSDK.initSDK(appKey: AppConfig.kakaoNativeKey)
        SDKInitializer.InitSDK(appKey: AppConfig.kakaoNativeKey)
    }
    

    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
