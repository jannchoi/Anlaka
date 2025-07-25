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
    
    // 탭 로드 상태 추적
    @State private var loadedTabs: Set<Tab> = [.home] // 기본 탭만 로드
    
    init(di: DIContainer) {
        self.di = di
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 지연 로딩을 위한 조건부 뷰 렌더링
            ZStack {
                // Home Tab - 조건부 로딩
                if shouldLoadTab(.home) {
                    NavigationStack(path: $homePath) {
                        createOrGetCachedView(for: .home) {
                            HomeView(di: di, path: $homePath)
                        }
                    }
                    .opacity(routingStateManager.currentTab == .home ? 1 : 0)
                    .allowsHitTesting(routingStateManager.currentTab == .home)
                    .onAppear {
                        CurrentScreenTracker.shared.setCurrentScreen(.home)
                        markTabAsLoaded(.home)
                    }
                }
                
                // Community Tab - 조건부 로딩
                if shouldLoadTab(.community) {
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
                
                // Reserved Tab - 조건부 로딩
                if shouldLoadTab(.reserved) {
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
                
                // MyPage Tab - 조건부 로딩
                if shouldLoadTab(.myPage) {
                    NavigationStack(path: $myPagePath) {
                        createOrGetCachedView(for: .myPage) {
                            MyPageView(di: di, path: $myPagePath)
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: myPagePath)
                    .opacity(routingStateManager.currentTab == .myPage ? 1 : 0)
                    .allowsHitTesting(routingStateManager.currentTab == .myPage)
                    .onAppear {
                        CurrentScreenTracker.shared.setCurrentScreen(.profile)
                        markTabAsLoaded(.myPage)
                    }
                }
            }
            
            if shouldShowTabBar {
                tabBar
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: 0)
        }
        .onChange(of: routingStateManager.pendingNavigation) { navigation in
            guard let navigation = navigation else { return }
            guard routingStateManager.isNavigationInProgress else { return }
            handlePendingNavigation(navigation)
        }
        .onChange(of: routingStateManager.currentTab) { newTab in
            // 탭 전환 시 캐시 관리
            handleTabChange(to: newTab)
        }
        .customNotificationBanner()
    }
    
    // MARK: - 탭 로딩 관리
    
    /// 탭이 로드되어야 하는지 확인
    private func shouldLoadTab(_ tab: Tab) -> Bool {
        // 현재 선택된 탭이거나 이미 로드된 탭
        let isCurrentTab = (tab == .home && routingStateManager.currentTab == .home) ||
                          (tab == .community && routingStateManager.currentTab == .community) ||
                          (tab == .reserved && routingStateManager.currentTab == .reserved) ||
                          (tab == .myPage && routingStateManager.currentTab == .myPage)
        return isCurrentTab || loadedTabs.contains(tab)
    }
    
    /// 탭을 로드된 것으로 표시
    private func markTabAsLoaded(_ tab: Tab) {
        loadedTabs.insert(tab)
    }
    
    /// 탭 전환 처리
    private func handleTabChange(to newTab: RoutingStateManager.Tab) {
        let myTabViewTab = Tab(rawValue: newTab.rawValue) ?? .home

        
        // 새 탭이 로드되지 않았다면 로드
        if !loadedTabs.contains(myTabViewTab) {
            loadedTabs.insert(myTabViewTab)
        }
        
        // 메모리 부족 시 비활성 탭 캐시 정리
        if loadedTabs.count > 2 {
            tabCache.clearInactiveTabCaches(activeTab: myTabViewTab)
        }
    }
    
    // MARK: - 캐시된 뷰 생성/조회
    

    
    // ViewBuilder 밖에서 캐시 저장 처리
    private func cacheView<T: View>(_ view: T, for tab: Tab) {
        DispatchQueue.main.async {
            self.tabCache.setCachedView(view, for: tab)
        }
    }
    
    /// 캐시된 뷰를 생성하거나 조회
    private func createOrGetCachedView<T: View>(for tab: Tab, @ViewBuilder createView: @escaping () -> T) -> T {
        if let cachedView = tabCache.getCachedView(for: tab, as: T.self) {
            return cachedView
        } else {
            let newView = createView()
            // 캐시 저장을 완전히 분리
            DispatchQueue.main.async {
                self.tabCache.setCachedView(newView, for: tab)
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
                        Text("홈")
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
                        Text("커뮤니티")
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
                    Image(routingStateManager.currentTab == .reserved ? "User_Fill" : "User_Empty")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30)
                    if routingStateManager.currentTab == .reserved {
                        Text("예약")
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
                    Image(routingStateManager.currentTab == .myPage ? "Setting_Fill" : "Setting_Empty")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30)
                    if routingStateManager.currentTab == .myPage {
                        Text("마이")
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

