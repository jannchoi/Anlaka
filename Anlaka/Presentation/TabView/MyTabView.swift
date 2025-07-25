//
//  MyTabView.swift
//  Anlaka
//
//  Created by 최정안 on 5/15/25.
//

import SwiftUI

struct MyTabView: View {
    let di: DIContainer
    @StateObject private var routingStateManager = RoutingStateManager.shared
    @StateObject private var tabCache = TabViewCache.shared
    
    enum Tab: Int, CaseIterable {
        case home = 0, community = 1, reserved = 2, myPage = 3
    }
    
    // selected를 computed property로 변경하여 RoutingStateManager와 동기화
    private var selected: Tab {
        // RoutingStateManager.Tab을 MyTabView.Tab으로 변환
        switch routingStateManager.currentTab {
        case .home:
            return .home
        case .community:
            return .community
        case .reserved:
            return .reserved
        case .myPage:
            return .myPage
        }
    }
    
    // 각 탭의 NavigationPath
    @State private var communityPath = NavigationPath()
    @State private var homePath = NavigationPath()
    @State private var reservedPath = NavigationPath()
    @State private var myPagePath = NavigationPath()
    
    // 탭 로드 상태 추적 (단순화)
    @State private var loadedTabs: Set<Tab> = [.home] // 기본 탭만 로드
    
    init(di: DIContainer) {
        self.di = di
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 단순한 탭 콘텐츠 레이어
            tabContentLayer
            
            if shouldShowTabBar {
                tabBar
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: 0)
        }
        .onChange(of: routingStateManager.pendingNavigation) { navigation in
            // nil인 경우
            guard let navigation = navigation else { return }
            // 이미 처리 중인 경우 (isNavigationInProgress가 true여야 처리 가능)
            guard routingStateManager.isNavigationInProgress else { return }
            handlePendingNavigation(navigation)
        }
        .onChange(of: routingStateManager.currentTab) { newTab in
            // 탭 전환 시 간단한 로드 관리
            handleTabChange(to: newTab)
        }
        .onAppear {
            CurrentScreenTracker.shared.setCurrentScreen(.home)
        }
        .customNotificationBanner()
    }
    
    // MARK: - 단순한 탭 콘텐츠 레이어
    @ViewBuilder
    private var tabContentLayer: some View {
        ZStack {
            // Home Tab - 단순한 조건부 로딩
            if shouldLoadTab(.home) {
                homeTabView
            }
            
            // Community Tab - 단순한 조건부 로딩
            if shouldLoadTab(.community) {
                communityTabView
            }
            
            // Reserved Tab - 단순한 조건부 로딩
            if shouldLoadTab(.reserved) {
                reservedTabView
            }
            
            // MyPage Tab - 단순한 조건부 로딩
            if shouldLoadTab(.myPage) {
                myPageTabView
            }
        }
    }
    
    // MARK: - 각 탭 뷰 (이전 코드 스타일 유지)
    @ViewBuilder
    private var homeTabView: some View {
        NavigationStack(path: $homePath) {
            createOrGetCachedView(for: .home) {
                HomeView(di: di, path: $homePath)
            }
            .navigationDestination(for: String.self) { estateId in
                EstateDetailView(di: di, estateId: estateId)
            }
        }
        .opacity(routingStateManager.currentTab == .home ? 1 : 0)
        .allowsHitTesting(routingStateManager.currentTab == .home)
        .onAppear {
            CurrentScreenTracker.shared.setCurrentScreen(.home)
            markTabAsLoaded(.home)
        }
    }
    
    @ViewBuilder
    private var communityTabView: some View {
        NavigationStack(path: $communityPath) {
            createOrGetCachedView(for: .community) {
                CommunityView(di: di, path: $communityPath)
            }
            .navigationDestination(for: String.self) { postId in
                PostDetailView(postId: postId, di: di, path: $communityPath)
            }
        }
        .opacity(routingStateManager.currentTab == .community ? 1 : 0)
        .allowsHitTesting(routingStateManager.currentTab == .community)
        .onAppear {
            CurrentScreenTracker.shared.setCurrentScreen(.community)
            markTabAsLoaded(.community)
        }
    }
    
    @ViewBuilder
    private var reservedTabView: some View {
        NavigationStack(path: $reservedPath) {
            createOrGetCachedView(for: .reserved) {
                RerservedEstatesView(di: di, path: $reservedPath)
            }
        }
        .opacity(routingStateManager.currentTab == .reserved ? 1 : 0)
        .allowsHitTesting(routingStateManager.currentTab == .reserved)
        .onAppear {
            CurrentScreenTracker.shared.setCurrentScreen(.estateDetail)
            markTabAsLoaded(.reserved)
        }
    }
    
    @ViewBuilder
    private var myPageTabView: some View {
        NavigationStack(path: $myPagePath) {
            createOrGetCachedView(for: .myPage) {
                MyPageView(di: di, path: $myPagePath)
            }
        }
        .opacity(routingStateManager.currentTab == .myPage ? 1 : 0)
        .allowsHitTesting(routingStateManager.currentTab == .myPage)
        .onAppear {
            CurrentScreenTracker.shared.setCurrentScreen(.profile)
            markTabAsLoaded(.myPage)
        }
    }
    
    // MARK: - 단순한 로딩 관리
    private func shouldLoadTab(_ tab: Tab) -> Bool {
        return loadedTabs.contains(tab) || routingStateManager.currentTab.rawValue == tab.rawValue
    }
    
    private func markTabAsLoaded(_ tab: Tab) {
        loadedTabs.insert(tab)
    }
    
    /// 탭 전환 처리 (단순화)
    private func handleTabChange(to newTab: RoutingStateManager.Tab) {
        let myTabViewTab = Tab(rawValue: newTab.rawValue) ?? .home
        
        // 새 탭이 로드되지 않았다면 로드
        if !loadedTabs.contains(myTabViewTab) {
            loadedTabs.insert(myTabViewTab)
        }
        
        // 메모리 관리를 위한 간단한 캐시 정리 (2개 이상 로드된 경우에만)
        if loadedTabs.count > 2 {
            // 현재 탭과 이전 탭만 유지
            let currentTab = myTabViewTab
            let previousTab = Tab(rawValue: routingStateManager.currentTab.rawValue) ?? .home
            loadedTabs = [currentTab, previousTab]
        }
    }
    
    // MARK: - 캐시된 뷰 생성/조회 (단순화)
    private func createOrGetCachedView(for tab: Tab, @ViewBuilder createView: @escaping () -> some View) -> AnyView {
        if let cachedView = tabCache.getCachedView(for: tab) {
            return cachedView
        } else {
            let newView = AnyView(createView())
            DispatchQueue.main.async {
                self.tabCache.cacheView(newView, for: tab)
            }
            return newView
        }
    }
    
    private func handlePendingNavigation(_ navigation: RoutingStateManager.NavigationDestination) {
        switch navigation {
        case .chatRoom(let roomId):
            // 1. MyPage 탭으로 전환
            routingStateManager.currentTab = .myPage
            // 2. NavigationPath 리셋 및 목표 채팅방 추가 (애니메이션과 함께)
            withAnimation(.easeInOut(duration: 0.3)) {
                resetNavigationPath(&myPagePath)
                myPagePath.append(AppRoute.MyPageRoute.chatRoom(roomId: roomId))
            }
        case .estateDetail(let estateId):
            routingStateManager.currentTab = .home
            resetNavigationPath(&homePath)
        case .postDetail(let postId):
            routingStateManager.currentTab = .community
            resetNavigationPath(&communityPath)
            communityPath.append(postId)
        case .profile:
            routingStateManager.currentTab = .myPage
            resetNavigationPath(&myPagePath)
            myPagePath.append(AppRoute.MyPageRoute.editProfile)
        case .settings:
            routingStateManager.currentTab = .myPage
            resetNavigationPath(&myPagePath)
        }
        // 네비게이션 완료 후 상태 초기화 (즉시)
        routingStateManager.completeNavigation()
    }
    
    private var shouldShowTabBar: Bool {
        switch routingStateManager.currentTab {
        case .home:
            return homePath.isEmpty
        case .community:
            return communityPath.isEmpty
        case .reserved:
            return reservedPath.isEmpty
        case .myPage:
            return myPagePath.isEmpty
        }
    }
    
    /// NavigationPath를 효율적으로 리셋하는 헬퍼 메서드
    private func resetNavigationPath(_ path: inout NavigationPath) {
        if !path.isEmpty {
            path = NavigationPath()
        }
    }
    
    var tabBar: some View {
        HStack {
            Spacer()
            Button {
                routingStateManager.currentTab = .home
                CurrentScreenTracker.shared.setCurrentScreen(.home)
            } label: {
                VStack(alignment: .center) {
                    Image(routingStateManager.currentTab == .home ? "Home_Fill" : "Home_Empty")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30)
                    if routingStateManager.currentTab == .home {
                        Text("")
                            .font(.pretendardCaption2)
                    }
                }
            }
            .foregroundStyle(routingStateManager.currentTab == .home ? Color.DeepForest : Color.Deselected)
            Spacer()
            Button {
                routingStateManager.currentTab = .community
                CurrentScreenTracker.shared.setCurrentScreen(.community)
            } label: {
                VStack(alignment: .center) {
                    Image(routingStateManager.currentTab == .community ? "Browser_Fill" : "Browser_Empty")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30)
                   if routingStateManager.currentTab == .community {
                        Text("")
                            .font(.pretendardCaption2)
                    }
                }
            }
            .foregroundStyle(routingStateManager.currentTab == .community ? Color.DeepForest : Color.Deselected)
            Spacer()
            Button {
                routingStateManager.currentTab = .reserved
                CurrentScreenTracker.shared.setCurrentScreen(.estateDetail)
            } label: {
                VStack(alignment: .center) {
                    Image(routingStateManager.currentTab == .reserved ? "Interest_Fill" : "Interest_Empty")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30)
                    if routingStateManager.currentTab == .reserved {
                        Text("")
                            .font(.pretendardCaption2)
                    }
                }
            }
            .foregroundStyle(routingStateManager.currentTab == .reserved ? Color.DeepForest : Color.Deselected)
            Spacer()
            Button {
                routingStateManager.currentTab = .myPage
                CurrentScreenTracker.shared.setCurrentScreen(.profile)
            } label: {
                VStack(alignment: .center) {
                    Image(routingStateManager.currentTab == .myPage ? "User_Fill" : "User_Empty")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30)
                    if routingStateManager.currentTab == .myPage {
                        Text("")
                            .font(.pretendardCaption2)
                    }
                }
            }
            .foregroundStyle(routingStateManager.currentTab == .myPage ? Color.DeepForest : Color.Deselected)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white)
        .shadow(color: .black.opacity(0.1), radius: 8, y: -2)
    }
}

