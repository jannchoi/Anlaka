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
    
    @State private var selected: Tab = .home
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
                .opacity(selected == .home ? 1 : 0)
                .allowsHitTesting(selected == .home)
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
                .opacity(selected == .community ? 1 : 0)
                .allowsHitTesting(selected == .community)
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
                .opacity(selected == .reserved ? 1 : 0)
                .allowsHitTesting(selected == .reserved)
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
                .opacity(selected == .myPage ? 1 : 0)
                .allowsHitTesting(selected == .myPage)
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
        .onChange(of: routingStateManager.currentTab) { newTab in
            selected = Tab(rawValue: newTab.rawValue) ?? .home
        }
        .onChange(of: routingStateManager.pendingNavigation) { navigation in
            if let navigation = navigation {
                handlePendingNavigation(navigation)
            }
        }
    }
    

    
    private func handlePendingNavigation(_ navigation: RoutingStateManager.NavigationDestination) {
        print("📱 MyTabView에서 대기 중인 네비게이션 처리: \(navigation)")
        
        switch navigation {
        case .chatRoom(let roomId):
            print("📱 채팅방으로 이동: \(roomId)")
            selected = .myPage
            myPagePath.append(AppRoute.MyPageRoute.chatRoom(roomId: roomId))
            print("📱 MyPage 탭 선택 및 채팅방 경로 추가 완료")
            
        case .estateDetail(let estateId):
            selected = .home
            // EstateDetailView로 이동하는 로직 추가 필요
            
        case .postDetail(let postId):
            selected = .community
            communityPath.append(postId)
            
        case .profile:
            selected = .myPage
            myPagePath.append(AppRoute.MyPageRoute.editProfile)
            
        case .settings:
            selected = .myPage
            // 설정 화면으로 이동하는 로직 추가 필요
        }
        
        // 네비게이션 완료 후 상태 초기화
        routingStateManager.completeNavigation()
        print("📱 네비게이션 완료 - 상태 초기화됨")
    }
    
    private var shouldShowTabBar: Bool {
        switch selected {
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
    
    var tabBar: some View {
        HStack {
            Spacer()
            Button {
                selected = .home
                CurrentScreenTracker.shared.setCurrentScreen(.home)
            } label: {
                VStack(alignment: .center) {
                    Image(selected == .home ? "Home_Fill" : "Home_Empty")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30)
                    if selected == .home {
                        Text("홈")
                            .font(.pretendardCaption2)
                    }
                }
            }
            .foregroundStyle(selected == .home ? Color.DeepForest : Color.Deselected)
            Spacer()
            Button {
                selected = .community
                CurrentScreenTracker.shared.setCurrentScreen(.community)
            } label: {
                VStack(alignment: .center) {
                    Image(selected == .community ? "Browser_Fill" : "Browser_Empty")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30)
                    if selected == .community {
                        Text("커뮤니티")
                            .font(.pretendardCaption2)
                    }
                }
            }
            .foregroundStyle(selected == .community ? Color.DeepForest : Color.Deselected)
            Spacer()
            Button {
                selected = .reserved
                CurrentScreenTracker.shared.setCurrentScreen(.estateDetail)
            } label: {
                VStack(alignment: .center) {
                    Image(selected == .reserved ? "User_Fill" : "User_Empty")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30)
                    if selected == .reserved {
                        Text("예약")
                            .font(.pretendardCaption2)
                    }
                }
            }
            .foregroundStyle(selected == .reserved ? Color.DeepForest : Color.Deselected)
            Spacer()
            Button {
                selected = .myPage
                CurrentScreenTracker.shared.setCurrentScreen(.profile)
            } label: {
                VStack(alignment: .center) {
                    Image(selected == .myPage ? "Setting_Fill" : "Setting_Empty")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30)
                    if selected == .myPage {
                        Text("마이")
                            .font(.pretendardCaption2)
                    }
                }
            }
            .foregroundStyle(selected == .myPage ? Color.DeepForest : Color.Deselected)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white)
        .shadow(color: .black.opacity(0.1), radius: 8, y: -2)
    }
}

