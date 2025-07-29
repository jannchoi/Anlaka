//
//  TabViewCache.swift
//  Anlaka
//
//  Created by 최정안 on 5/15/25.
//

import SwiftUI

// MARK: - TabView 캐시 관리
@MainActor
final class TabViewCache: ObservableObject {
    static let shared = TabViewCache()
    
    // 캐시된 뷰들 (메모리 최적화)
    private var cachedViews: [String: Any] = [:]
    
    // 캐시된 데이터들 (5분 만료)
    private var dataCache: [String: (data: Any, timestamp: TimeInterval)] = [:]
    private let cacheExpiration: TimeInterval = 5 * 60 // 5분
    
    private init() {}
    
    // MARK: - 뷰 캐시 관리
    
    /// 뷰 캐시 저장
    func setCachedView<T: View>(_ view: T, for tab: MyTabView.Tab) {
        let key = "view_\(tab)"
        cachedViews[key] = view
        print("📦 뷰 캐시 저장: \(tab)")
    }
    
    /// 뷰 캐시 조회
    func getCachedView<T: View>(for tab: MyTabView.Tab, as type: T.Type) -> T? {
        let key = "view_\(tab)"
        return cachedViews[key] as? T
    }
    
    /// 뷰 캐시 삭제
    func clearCachedView(for tab: MyTabView.Tab) {
        let key = "view_\(tab)"
        cachedViews.removeValue(forKey: key)
        print("🗑️ 뷰 캐시 삭제: \(tab)")
    }
    
    // MARK: - 데이터 캐시 관리
    
    /// 데이터 캐시 저장
    func setCachedData<T>(_ data: T, for tab: MyTabView.Tab) {
        let key = "data_\(tab)_\(String(describing: T.self))"
        dataCache[key] = (data: data, timestamp: Date().timeIntervalSince1970)
        print("📦 데이터 캐시 저장: \(tab) - \(String(describing: T.self))")
    }
    
    /// 데이터 캐시 조회
    func getCachedData<T>(for tab: MyTabView.Tab, as type: T.Type) -> T? {
        let key = "data_\(tab)_\(String(describing: T.self))"
        guard let cached = dataCache[key] else { return nil }
        
        // 만료 확인
        let now = Date().timeIntervalSince1970
        if now - cached.timestamp > cacheExpiration {
            dataCache.removeValue(forKey: key)
            print("⏰ 캐시 만료: \(tab) - \(String(describing: T.self))")
            return nil
        }
        
        return cached.data as? T
    }
    
    /// 데이터 캐시 삭제
    func clearCachedData(for tab: MyTabView.Tab) {
        let keysToRemove = dataCache.keys.filter { $0.hasPrefix("data_\(tab)_") }
        for key in keysToRemove {
            dataCache.removeValue(forKey: key)
        }
        print("🗑️ 데이터 캐시 삭제: \(tab)")
    }
    
    // MARK: - 전체 캐시 관리
    
    /// 모든 캐시 정리
    func clearAllCaches() {
        cachedViews.removeAll()
        dataCache.removeAll()
        print("🗑️ 모든 탭 캐시 정리")
    }
    
    func clearInactiveTabCaches(activeTab: MyTabView.Tab) {
        for tab in MyTabView.Tab.allCases {
            if tab != activeTab {
                clearCachedView(for: tab)
                clearCachedData(for: tab)
            }
        }
        print("🗑️ 비활성 탭 캐시 정리 (활성 탭: \(activeTab))")
    }
} 