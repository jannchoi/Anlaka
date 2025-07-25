//
//  MyTabView.swift
//  Anlaka
//
//  Created by 최정안 on 6/9/25.
//

import SwiftUI

struct MyTabView: View {
    let di: DIContainer
    
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
            }
            
            if shouldShowTabBar {
                tabBar
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: 0)
        }
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
            } label: {
                VStack(alignment: .center) {
                    Image(selected == .reserved ? "Interest_Fill" : "Interest_Empty")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30)
                    if selected == .reserved {
                        Text("관심매물")
                            .font(.pretendardCaption2)
                    }
                }
            }
            .foregroundStyle(selected == .reserved ? Color.DeepForest : Color.Deselected)
            Spacer()
            Button {
                selected = .myPage
            } label: {
                VStack(alignment: .center) {
                    Image(selected == .myPage ? "User_Fill" : "User_Empty")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30)
                    if selected == .myPage {
                        Text("프로필")
                            .font(.pretendardCaption2)
                    }
                }
            }
            .foregroundStyle(selected == .myPage ? Color.DeepForest : Color.Deselected)
            Spacer()
        }
        .padding(.vertical)
        .frame(height: 78)
        .frame(maxWidth: .infinity)
        .background {
            Rectangle()
                .fill(Color.white)
                .clipShape(
                    .rect(
                        topLeadingRadius: 24,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 24
                    )
                )
                .shadow(color: .black.opacity(0.15), radius: 8, y: 2)
        }
    }
}

