//
//  MyTabView.swift
//  Anlaka
//
//  Created by 최정안 on 6/9/25.
//

import SwiftUI

struct MyTabView: View {
    let di: DIContainer
    @StateObject private var routingStateManager = RoutingStateManager.shared
    
    enum Tab: Int, CaseIterable {
        case home = 0, community = 1, reserved = 2, myPage = 3
    }
    
    // selected를 computed property로 변경하여 RoutingStateManager와 동기화
    private var selected: Tab {
        Tab(rawValue: routingStateManager.currentTab.rawValue) ?? .home
    }
    @State private var communityPath = NavigationPath()
    @State private var homePath = NavigationPath()
    @State private var reservedPath = NavigationPath()
    @State private var myPagePath = NavigationPath()
    
    // 각 탭의 뷰 인스턴스를 한 번만 생성하여 재사용
    @State private var communityView: CommunityView?
    @State private var homeView: HomeView?
    @State private var reservedView: RerservedEstatesView?
    @State private var myPageView: MyPageView?
    
    init(di: DIContainer) {
        self.di = di
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // LazyView를 사용하여 선택된 탭만 생성하되, 한 번 생성된 뷰는 재사용
            ZStack {
                // Home Tab
                NavigationStack(path: $homePath) {
                    Group {
                        if let homeView = homeView {
                            homeView
                        } else {
                            LazyView(content: HomeView(di: di, path: $homePath))
                                .onAppear {
                                    if homeView == nil {
                                        self.homeView = HomeView(di: di, path: $homePath)
                                    }
                                }
                        }
                    }
                }
                .opacity(routingStateManager.currentTab == .home ? 1 : 0)
                .allowsHitTesting(routingStateManager.currentTab == .home)
                .onAppear {
                    CurrentScreenTracker.shared.setCurrentScreen(.home)
                }
                
                // Community Tab
                NavigationStack(path: $communityPath) {
                    Group {
                        if let communityView = communityView {
                            communityView
                        } else {
                            LazyView(content: CommunityView(di: di, path: $communityPath))
                                .onAppear {
                                    if communityView == nil {
                                        self.communityView = CommunityView(di: di, path: $communityPath)
                                    }
                                }
                        }
                    }
                    .navigationDestination(for: String.self) { postId in
                        PostDetailView(postId: postId, di: di, path: $communityPath)
                    }
                }
                .opacity(routingStateManager.currentTab == .community ? 1 : 0)
                .allowsHitTesting(routingStateManager.currentTab == .community)
                .onAppear {
                    CurrentScreenTracker.shared.setCurrentScreen(.community)
                }
                
                // Reserved Tab
                NavigationStack(path: $reservedPath) {
                    Group {
                        if let reservedView = reservedView {
                            reservedView
                        } else {
                            LazyView(content: RerservedEstatesView(di: di, path: $reservedPath))
                                .onAppear {
                                    if reservedView == nil {
                                        self.reservedView = RerservedEstatesView(di: di, path: $reservedPath)
                                    }
                                }
                        }
                    }
                }
                .opacity(routingStateManager.currentTab == .reserved ? 1 : 0)
                .allowsHitTesting(routingStateManager.currentTab == .reserved)
                .onAppear {
                    CurrentScreenTracker.shared.setCurrentScreen(.estateDetail)
                }
                
                // MyPage Tab
                NavigationStack(path: $myPagePath) {
                    Group {
                        if let myPageView = myPageView {
                            myPageView
                        } else {
                            LazyView(content: MyPageView(di: di, path: $myPagePath))
                                .onAppear {
                                    if myPageView == nil {
                                        self.myPageView = MyPageView(di: di, path: $myPagePath)
                                    }
                                }
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: myPagePath)
                .opacity(routingStateManager.currentTab == .myPage ? 1 : 0)
                .allowsHitTesting(routingStateManager.currentTab == .myPage)
                .onAppear {
                    CurrentScreenTracker.shared.setCurrentScreen(.profile)
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
        // selected가 computed property로 변경되어 onChange 불필요
        .onChange(of: routingStateManager.pendingNavigation) { navigation in
            // nil인 경우
            guard let navigation = navigation else {
                return
            }
            
            // 이미 처리 중인 경우 (isNavigationInProgress가 true여야 처리 가능)
            guard routingStateManager.isNavigationInProgress else {
                return
            }
            
            handlePendingNavigation(navigation)
        }
        .customNotificationBanner() // 새로운 커스텀 알림 배너 추가
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

